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
  end

end
