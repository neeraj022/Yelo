# spec/support/auth_helpers.rb
module AuthHelpers
  def authWithUser(user)
    # request.headers['X-ACCESS-TOKEN'] = "#{user.auth_token},device_id=#{user.encrypt_device_id}"
    auth = ActionController::HttpAuthentication::Token.encode_credentials(user.auth_token ,{:device_id => user.encrypt_device_id})
    request.env['HTTP_AUTHORIZATION'] = auth
  end

  def clearToken
  	request.env['HTTP_AUTHORIZATION'] = nil
    # request.headers['X-ACCESS-TOKEN'] = nil
  end
end


