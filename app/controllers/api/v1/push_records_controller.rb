class Api::V1::PushRecordsController < Api::V1::BaseController
  before_action :authenticate_user!

  # GET /notifications
  def index
    @notifications = current_user.notifications.ne(n_status: PushRecord::N_STATUS[:seen])
    render json: @notifications
  rescue => e
     rescue_message(e) 
  end
  
  # POST /notifications/:id/seen
  def update_seen_status
    @notification = PushRecord.where(_id: params[:id]).first
    if @notification.update_attributes(n_status: PushRecord::N_STATUS[:seen])
      render json: {status: "ok"}
    else
      render json: {status: "error"}
    end
  rescue => e
     rescue_message(e) 
  end

end
