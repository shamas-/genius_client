require 'net/http'
require 'set'

class GeniusController < ApplicationController
  API_URI = 'https://api.genius.com'

  def index
    if params[:artist_id].present?
      get_songs(params[:artist_id].to_i, (params[:page].present? ? params[:page].to_i : 1))
    elsif params[:query].present?
      @query = params[:query]
      uri = URI(API_URI)
      uri.path = '/search'
      uri.query = URI.encode_www_form({ q: @query })
      response = Net::HTTP.get(uri, api_headers)
      json_response = JSON.parse response
      artists = Set.new
      json_response['response']['hits'].each do |hit|
        hit['result']['primary_artists'].each do |artist|
          artists << [ artist['name'], artist['id'] ]
        end
      end

      if artists.size != 1
        @artists = artists
      else
        get_songs artists.first.second
      end
    end
  end

  private

  SONGS_PER_PAGE = 2
  def get_songs(artist_id, page = 1)
    uri = URI(API_URI)
    uri.path = "/artists/#{artist_id}/songs"
    uri.query = URI.encode_www_form({ per_page: SONGS_PER_PAGE,
                                      page: page,
                                      sort: :popularity })
    response = Net::HTTP.get(uri, api_headers)
    json_response = JSON.parse response

    @canonical_artist_name = json_response['response']['songs'].present? ?
                               get_artist_name(artist_id, json_response['response']['songs']) :
                               nil

    song_titles = json_response['response']['songs'].map { |song| song['title_with_featured'] }
    @song_titles = song_titles

    @artist_id = artist_id
    if page > 1
      @previous_page = page - 1
    end
    if json_response['response']['next_page'].present? && @song_titles.size == SONGS_PER_PAGE
      @next_page = json_response['response']['next_page']
    end
  end

  def get_artist_name(artist_id, songs)
    songs.each do |song|
      song['primary_artists'].each do |an_artist|
        return an_artist['name'] if an_artist['id'] == artist_id
      end
      song['featured_artists'].each do |featured_artist|
        return featured_artist['name'] if featured_artist['id'] == artist_id
      end
    end

    uri = URI(API_URI)
    uri.path = "/artists/#{artist_id}"
    response = Net::HTTP.get(uri, api_headers)
    JSON.parse(response)['response']['artist']['name']
  end

  def api_headers
    { Accept: 'application/json',
      Authorization: "Bearer #{ENV['GENIUS_API_TOKEN']}" }
  end
end
