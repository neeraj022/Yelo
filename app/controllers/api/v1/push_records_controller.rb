class Api::V1::PushRecordsController < Api::V1::BaseController
  #before_action :authenticate_user!

  # GET /notifications
  def index
    current_user = User.find('562616ef79656c2646510000')
    @notifications = paginate current_user.push_records.ne(n_status: PushRecord::N_STATUS[:seen]).order('push_records.created_at DESC'), per_page: 20
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
