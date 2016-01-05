class Api::V1::PushRecordsController < Api::V1::BaseController
  before_action :authenticate_user!

  # GET /notifications
  def index
    @time_stamp = params[:time_stamp]
    unless @time_stamp.blank? 
      index = params[:index].blank? ? '0' : params[:index]
      @notifications = paginate current_user.push_records.ne(n_status: PushRecord::N_STATUS[:seen]).select{|n|n.created_at >= @time_stamp}.sort_by{|arr|arr[:created_at]}.reverse[index.to_i,20], per_page: 20
    else 
      @notifications = []
    end
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
