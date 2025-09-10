require "test_helper"

class Api::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @valid_params = {
      user: {
        name: "Test User",
        email: "test@example.com",
        phone: "010-1234-5678",
        birth_date: "1990-01-01"
      }
    }
  end

  test "should get index" do
    get api_users_url
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_instance_of Array, json_response
  end

  test "should show user" do
    get api_user_url(@user)
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @user.email, json_response["email"]
  end

  test "should create user with valid params" do
    assert_difference("User.count", 1) do
      post api_users_url, params: @valid_params
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal "Test User", json_response["name"]
  end

  test "should not create user with invalid params" do
    invalid_params = { user: { name: "", email: "" } }

    assert_no_difference("User.count") do
      post api_users_url, params: invalid_params
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "should update user" do
    patch api_user_url(@user), params: { user: { name: "Updated Name" } }
    assert_response :success

    @user.reload
    assert_equal "Updated Name", @user.name
  end

  test "should destroy user" do
    assert_difference("User.count", -1) do
      delete api_user_url(@user)
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent user" do
    get api_user_url(id: 999999)
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal "User not found", json_response["error"]
  end
end
