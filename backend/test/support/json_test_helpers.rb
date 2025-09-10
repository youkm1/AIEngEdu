module JsonTestHelpers
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  def assert_json_success_response(message = nil)
    assert_equal true, json_response[:success]
    assert_equal message, json_response[:message] if message
  end

  def assert_json_error_response(message = nil)
    assert_equal false, json_response[:success]
    assert_equal message, json_response[:message] if message
  end
end
