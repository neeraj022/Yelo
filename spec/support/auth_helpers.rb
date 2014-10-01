# spec/support/auth_helpers.rb
module AuthHelpers
  def authWithUser (user)
    request.headers['X-ACCESS-TOKEN'] = "#{user.auth_token},device_id=#{user.encrypt_device_id}"
  end

  def clearToken
    request.headers['X-ACCESS-TOKEN'] = nil
  end
end


