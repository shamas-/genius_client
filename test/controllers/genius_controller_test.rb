require "test_helper"

class GeniusControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get genius_index_url
    assert_response :success
  end
end
