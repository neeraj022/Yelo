class Api::V1::ChatController < ApplicationController
  before_action :authenticate_user!
  
  # POST /chat
  def send
    ampq(params[:chat])
    render json: {}
  end

end
