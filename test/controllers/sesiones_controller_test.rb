require "test_helper"

class SesionesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get sesiones_new_url
    assert_response :success
  end

  test "should get create" do
    get sesiones_create_url
    assert_response :success
  end

  test "should get destroy" do
    get sesiones_destroy_url
    assert_response :success
  end
end
