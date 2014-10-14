class Api::V1::NotificationsController < ApplicationController
  before_action :authenticate_user!

  # GET /notifications
  def index
    @notifications = current_user.notifications.ne(n_status: Notification::N_STATUS[:seen])
    render json: @notifications
  rescue => e
     rescue_message(e) 
  end
  
  # POST /notifications/:id/seen
  def update_seen_status
    @notification = Notification.where(_id: params[:id]).first
    if @notification.update_attributes(n_status: Notification::N_STATUS[:seen])
      render json {status: "ok"}
    else
      render json {status: "error"}
    end
  rescue => e
     rescue_message(e) 
  end

end
