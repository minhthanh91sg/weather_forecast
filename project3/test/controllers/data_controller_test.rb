require 'test_helper'

class DataControllerTest < ActionController::TestCase
  test "should get loctions" do
    get :loctions
    assert_response :success
  end

  test "should get location_id" do
    get :location_id
    assert_response :success
  end

  test "should get post_code" do
    get :post_code
    assert_response :success
  end

end
