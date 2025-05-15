require 'application_system_test_case'

class SongsTest < ApplicationSystemTestCase
  def setup
    visit root_url
  end

  def search(query)
    fill_in 'query', with: query
    click_on SUBMIT
  end

  test 'visiting the index' do
    assert_text 'Get songs for artist:'
  end

  SUBMIT = 'Get’em'
  test 'one artist result shows songs' do
    search 'metallica'
    assert_text 'Songs by Metallica:'
    assert_text 'Enter Sandman'
    assert_text 'For Whom the Bell Tolls'
  end

  PREVIOUS = '< Previous'
  NEXT = 'Next >'
  test 'no pagination' do
    search 'Children of Nova'
    assert_no_link PREVIOUS
    assert_no_link NEXT
  end

  test 'pagination' do
    search 'metallica'
    assert_no_link PREVIOUS

    click_on NEXT
    assert_text 'Dyers Eve'
    assert_text 'Until It Sleeps'

    click_on PREVIOUS
    assert_text 'Enter Sandman'
    assert_text 'For Whom the Bell Tolls'

    (2..7).each do |page_number|
      click_on NEXT
      assert_text "Page #{page_number}"
    end
    assert_text 'Carpe Diem Baby'
    assert_text 'Sabbra Cadabra'
    assert_no_link NEXT
  end

  test 'multiple artists' do
    search 'boys'
    assert_text 'There are multiple results for “boys”. Choose which one you’d like to see songs for:'
    assert_link 'BTS'
    assert_link 'Don Henley'
  end

  test 'multiple artists songs' do
    search 'boys'
    click_on 'Don Henley'
    assert_text 'Hotel California' # Don Henley wrote the lyrics for this
    assert_text 'The Boys of Summer'
  end

  test 'artist not named in any song' do
    # there is an edge case in the API where the artist whose songs you request is not named anywhere in the song data returned
    visit root_url(artist_id: 41201, page: 19)
    assert_text 'Songs by Don Henley:'
  end

  test 'no artists returned' do
    search 'qwefqewfasdrtyeas'
    assert_text 'No artists were returned for that query.'
  end

  test 'genius api metadata error' do
    visit root_url(artist_id: 99999)
    assert_text 'There was an error accessing the Genius API.'
  end
end
