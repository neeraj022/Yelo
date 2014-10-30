class Api::V1::BaseController < ActionController::API
  # skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }
  skip_before_action :verify_authenticity_token
  include ActionController::MimeResponds
  include ActionController::Cookies
  include ActionController::HttpAuthentication::Token
  before_action :authenticate_user_from_token!

  # for active model serializers
  serialization_scope :current_user

  def authenticate_admin!
    if(current_user && current_user.is_admin?)
      return true
    else
      return false
    end
  end

  def rescue_message(e)
    render json: {error_message: Code.error_message(e), status: Code[:status_error] }, status: Code[:error_code]
  end

  private
    def authenticate_user_from_token!
      request.format = "json"
      user_token = token_and_options(request).presence
      return if user_token.blank?
      user_device_id = user_token[1][:device_id].presence 
      user = user_device_id && User.allowed.where(auth_token: user_token[0]).first
      if user && Devise.secure_compare(user.encrypt_device_id, user_device_id)
        sign_in user, store: false
      end
    end
end
