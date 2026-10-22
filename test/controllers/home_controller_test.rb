require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root renders" do
    get root_url
    assert_response :success
    assert_select "h1", "Todo App"
  end
end
