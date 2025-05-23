require "net/http"
require "set"

class GeniusController < ApplicationController
  API_URI = "https://api.genius.com"

  def index
    begin
      if params[:artist_id].present?
        get_songs(params[:artist_id].to_i, (params[:page].present? ? params[:page].to_i : 1))
      elsif params[:query].present?
        @query = params[:query]
        uri = URI(API_URI)
        uri.path = "/search"
        uri.query = URI.encode_www_form({ q: @query })
        response = Net::HTTP.get(uri, api_headers)
        json_response = JSON.parse response
        verify_response json_response
        artists = Set.new
        json_response["response"]["hits"].each do |hit|
          hit["result"]["primary_artists"].each do |artist|
            artists << [ artist["name"], artist["id"] ]
          end
        end

        if artists.size != 1
          @artists = artists
        else
          get_songs artists.first.second
        end
      end
    rescue StandardError => e
      logger.error e.message
      @error = true
    end
  end

  private

  SONGS_PER_PAGE = 20
  def get_songs(artist_id, page = 1)
    uri = URI(API_URI)
    uri.path = "/artists/#{artist_id}/songs"
    uri.query = URI.encode_www_form({ per_page: SONGS_PER_PAGE,
                                      page: page,
                                      sort: :popularity })
    response = Net::HTTP.get(uri, api_headers)
    json_response = JSON.parse response
    verify_response json_response

    @canonical_artist_name = json_response["response"]["songs"].present? ?
                               get_artist_name(artist_id, json_response["response"]["songs"]) :
                               nil

    song_titles = json_response["response"]["songs"].map { |song| song["title_with_featured"] }
    @song_titles = song_titles

    @artist_id = artist_id
    if page > 1
      @previous_page = page - 1
    end
    # The genius API has bugs with pagination:
    # 1. The current page can contain less than the per_page number of songs and yet there will still be a number value for the "next_page" key, instead of indicating that there is no next page by using a null value. If you fetch the next page it will probably be empty, but it will still have a value for next_page even then. Usually it takes several empty pages before the value is null. Which leads into the second problem.
    # 2. A heuristic implemented below is to overcome issue #1 is to check that the current page has per_page songs in it before making "Next >" navigable. (Assumption: if the number of results on the current page is less than per_page then the next page should be empty.) However, the API will still sometimes return fewer than per_page results even when the next page has content. So even though we ask for 20 results it returns 19. So then we make "Next >" NON-navigable but if you manually go to the next page it has 20 songs in it.
    # So genius’ "next_page" key is unreliable. If we want to reliably paginate for our customers then you probably need to push through their bugs by fully enumerating all of their API results for a given artist first. That implementation would be a concern for a production app.
    if json_response["response"]["next_page"].present? && @song_titles.size == SONGS_PER_PAGE
      @next_page = json_response["response"]["next_page"]
    end
  end

  def get_artist_name(artist_id, songs)
    songs.each do |song|
      song["primary_artists"].each do |an_artist|
        return an_artist["name"] if an_artist["id"] == artist_id
      end
      song["featured_artists"].each do |featured_artist|
        return featured_artist["name"] if featured_artist["id"] == artist_id
      end
    end

    uri = URI(API_URI)
    uri.path = "/artists/#{artist_id}"
    response = Net::HTTP.get(uri, api_headers)
    json_response = JSON.parse response
    verify_response json_response
    json_response["response"]["artist"]["name"]
  end

  def api_headers
    { Accept: "application/json",
      Authorization: "Bearer #{ENV['GENIUS_API_TOKEN']}" }
  end

  def verify_response(json_response)
    status_code = json_response["meta"]["status"]
    raise "Genius API returned error status #{status_code}" unless status_code == 200
  end
end
