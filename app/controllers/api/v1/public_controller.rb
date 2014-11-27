class Api::V1::PublicController < Api::V1::BaseController
  # GET /server_status
  def server_status
  	status = AppSetting.server_status
  	render json: status
  end

  # get /shares/:mobile_number
  def shares
  	num = User.mobile_number_format(params[:mobile_number])
    user = User.where(mobile_number: num[:mobile_number]).first
    count = user.shares.count
    render json: {share_count: count}
  rescue => e
    render json: {status: "No user present"}
  end

  def push
    case params[:type]
    when "wall_summary"
      notification = Notification.where(n_type: 2).last
      tags_hash = {services: 1, arts: 2, tech: 5 }
      obj = Notification.summary_wall_obj(tags_hash)
    when "wall_pin"
      notification = Notification.where(n_type: 3).last
    when "tagged_user"
      notification = Notification.where(n_type: 1).last
    when "contact_wall"
      notification = Notification.where(n_type: 4).last
    end
    obj = notification.notify_obj if params[:type] != "wall_summary"
    Notification.push_notify("android", [params[:push_id]], obj)
    render json: {status: "success"}
  end

end


  # N_CONS = {USER_TAG: 1, CREATE_WALL: 2, WALL_PIN: 3, CONTACT_WALL: 4}
  # N_STATUS = {FRESH: 0, SENT: 1, SEEN: 2, SUMMARY: 3}