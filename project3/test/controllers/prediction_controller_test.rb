require 'test_helper'

class PredictionControllerTest < ActionController::TestCase
  test "should get post_code" do
    get :post_code
    assert_response :success
  end

  test "should get lat_long" do
    get :lat_long
    assert_response :success
  end

end
