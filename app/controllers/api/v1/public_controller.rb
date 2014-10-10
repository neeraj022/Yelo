class Api::V1::PublicController < ApplicationController
  # GET /server_status
  def server_status
  	status = AppSetting.server_status
  	render json: status
  end

end
