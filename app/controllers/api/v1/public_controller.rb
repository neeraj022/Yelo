class Api::V1::PublicController < Api::V1::BaseController
  # GET /server_status
  def server_status
     platform = params[:platform]
        app_version = params[:app_version]
       unless platform.blank? && app_version.blank?
         setting = AppSetting.first
         if platform == "ios"
              app_version = app_version.gsub('.','')
            if app_version.to_i > setting.ios_force_update && app_version.to_i <= setting.ios_soft_update
              status = {code: 4, message:"We have an awesome update available for you, with lots of new features and bug fixes. Would you like to update now?" }
              render json: status
           elsif setting.ios_force_update > app_version.to_i
              status =  {code: 2, message: "Please update your app to be a part of yelo."}
              render json: status
           elsif  app_version.to_i > setting.android_soft_update
              status =  {code: 1, message: "Ok"}
              render json: status
           else
             status = {code: 3, message: "Server under maintenance."}
             render json: status
           end
        else
          if  app_version.to_i == 56
           status =  {code: 2, message: "Please update your app to be a part of yelo.",version_android: setting.version_android}
           render json: status
         elsif app_version.to_i > setting.android_force_update && app_version.to_i <= setting.android_soft_update
           status =  {code: 4, message: "We have an awesome update available for you, with lots of new features and bug fixes. Would you like to update now?",version_android: setting.version_android}
           render json: status
         elsif setting.android_force_update >= app_version.to_i
           status =  {code: 2, message: "Please update your app to be a part of yelo.",version_android: setting.version_android}
           render json: status
         elsif  app_version.to_i > setting.android_soft_update
           status =  {code: 1, message: "Ok",version_android: setting.version_android}
           render json: status
         else
           status = {code: 3, message: "Server under maintenance.",version_android: setting.version_android}
           render json: status
         end
        end
       else
  	status = AppSetting.server_status
  	render json: status
       end
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

  # GET /push
  def push
    case params[:type]
    when "wall_summary"
      notification = PushRecord.where(n_type: 2).last
      tags_hash = {services: 1, arts: 2, tech: 5 }
      obj = PushRecord.summary_wall_obj(tags_hash)
    when "wall_pin"
      notification = PushRecord.where(n_type: 3).last
    when "tagged_user"
      notification = PushRecord.where(n_type: 1).last
    when "contact_wall"
      notification = PushRecord.where(n_type: 4).last
    when "chat"
      obj = {collapse_key: "alert", message: "", resource: {name:
      "chat alert", dest: ""}}
    end
    obj = notification.notify_obj if (params[:type] != "wall_summary" && params[:type] != "chat")
    response = PushRecord.push_notify("android", [params[:push_id]], obj)
    render json: {status: "success", gcm: response.to_s}
  end

end


  # N_CONS = {USER_TAG: 1, CREATE_WALL: 2, WALL_PIN: 3, CONTACT_WALL: 4}
  # N_STATUS = {FRESH: 0, SENT: 1, SEEN: 2, SUMMARY: 3}
