class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:ping, :show, :create, :verify_serial_code, :verify_missed_call, :sms_serial_code]
  before_action :set_mobile_number, only: [:create, :verify_serial_code, :verify_missed_call, :sms_serial_code]
  
  # POST '/users'
  def create
    @user = User.where(mobile_number: params[:user][:mobile_number]).first
    if(@user.present?)
      existing_user
    else
      create_new_user
    end
  rescue => e
    rescue_message(e)
  end

  # GET '/users/:id'
  def show
    @user  = User.find(params[:id])
    # expires_in 5.minutes, :public => true
    render json: @user
  rescue => e
    rescue_message(e)
  end

  # GET /ping
  def ping
    render json: {status: :success}
  end

  # PUT/PATCH '/users/id'
  def update
    @user  = current_user
    if(params[:image].present?)
      @user.image = params[:image]
    elsif(params[:user][:ext_image_url].present?)
      @user.remote_image_url = params[:user][:ext_image_url]
      @user.ext_image_url = params[:user][:ext_image_url]
    end
    if(@user.update_attributes(user_params.merge(is_present: true)))
      render json: @user
    else
      render json: {error_message: @user.errors.full_messages},  status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  # POST 'users/verify_sms'
  def verify_serial_code
    @user = User.where(mobile_number: params[:user][:mobile_number], serial_code: params[:user][:serial_code]).first
    if(@user.present?)
      save_verified_user
    else
      render json: {error_message: "user not present"}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  # POST /sms_serial_code
  def sms_serial_code
    @user = User.where(mobile_number: params[:user][:mobile_number]).first
    if(@user.present?)
      send_sms
    else
      render json: {error_message: "user not present"}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end
 
  # POST '/users/verify_call'
  def verify_missed_call
   @user = User.where(mobile_number: params[:user][:mobile_number]).first
   @call = @user.verify_missed_call(params[:user][:missed_call_number].sub(/^\+*0+/, "")).body
   if(@call["status"] == "success")
     @user.call_verified =  true
     save_verified_user
   else
     render json: {error_message: "Invalid", call_response: @call}, status: Code[:error_code]
   end
  rescue => e
    rescue_message(e)
  end

  # POST 'users/interests'
  def interests
    @user = current_user
    tag_ids = Tag.verify_ids(params[:user][:interest_ids])
    @user.interest_ids = []
    if(@user.add_to_set(interest_ids: tag_ids))
       render json: {user: {interest_ids: @user.interest_ids}}
    else
       render json: {status: Code[:status_error], error_message: @user.errors.full_messages}, status: Code[:error_code]  
    end
  rescue => e
    rescue_message(e)
  end

  # POST /referral
  def register_referral
    User.register_referral(params[:referral_id], params[:device_id])
    render json: {status: "success"}
  rescue => e
    rescue_message(e)
  end

  # post api/v1/abuse
  def abuse
    case params[:type]
    when "wall"
      wall = Wall.where(_id: params[:id]).first
      wall.abuse(current_user.id)
    end
    render json: {status: "success"}
  rescue => e
    rescue_message(e)
  end

  # POST /users/contacts
  def contacts
    current_user.save_contacts(params[:hash_mobile_numbers])
    render json: {status: "success"}
  rescue => e
    rescue_message(e)
  end


  # POST /users/contacts_and_names
  def contacts_with_name
    current_user.save_contacts_with_name(params[:contacts])
    render json: {status: "success"}
  rescue => e
    rescue_message(e)
  end

  # GET /users/:user_id/recommends/tags
  def tag_recommends
    params[:user_id] = BSON::ObjectId.from_string(params[:user_id])
    @tag_obj = Wall.collection.aggregate(
      { "$unwind" => '$wall_items' },
      {
        "$match" => { "wall_items.user_id" => params[:user_id]} 
      },
      {
      "$project" => {
          "tag_id" => "$tag_id",
          "user_id" => "$wall_items.user_id",
          "tag_name" => "$tag_name"
         }
        },
      {"$group" => {
            "_id" => {"tag_id" => "$tag_id", "tag_name" => "$tag_name"}, "count" =>  {"$sum" => 1}}
      },
    )
    @tags = @tag_obj.map{|t| {name: t[:_id][:tag_name], id: t[:_id][:tag_id].to_s, count: t[:count] }}
    render json: {tags: @tags}
  rescue => e
    rescue_message(e)
  end

  #  # GET /users/:user_id/recommends/tags
  # def tag_recommends
  #   params[:user_id] = BSON::ObjectId.from_string(params[:user_id])
  #   @tag_obj = Wall.collection.aggregate(
  #        {
  #         "$match" => { "wall_items.user_id" => params[:user_id]} 
  #        },
  #       {"$group" => {
  #           "_id" => {"tag_id" => "$tag_id", "user_ids" => "$wall_items.user_id"}
  #         }
  #        })
  #   binding.pry
  #   @tags = Tag.get_user_tag_recommends(@tag_obj, params[:user_id])
  #   render json: {tags: @tags}
  # rescue => e
  #   rescue_message(e)
  # end

  # GET /users/:user_id/recommendations/tags
  def tag_recommendations
    params[:user_id] = BSON::ObjectId.from_string(params[:user_id])
    @tag_obj = Wall.collection.aggregate(
     {
      "$match" => { "tagged_users.user_id" => params[:user_id]} 
     },
    {"$group" => {
        "_id" => {"tag_id" => "$tag_id"}, 
        "tag_count" => {"$sum" => 1}}
     })
    @tags = Tag.get_tag_from_group(@tag_obj)
    render json: {tags: @tags}
  rescue => e
    rescue_message(e)
  end

  # GET /users/:user_id/recommends
  def recommends
    params[:user_id] = BSON::ObjectId.from_string(params[:user_id])
    t_users = Array.new
    walls = Wall.where("wall_items.user_id" => params[:user_id])
    if(params[:tag_id].present?)
      walls = walls.where(tag_id: params[:tag_id])
    end
    walls.each do |w|
      tag_name = w.tag_name
      t_users  << {tag_name: tag_name, wall_id: w.id.to_s, tagged_user: w.tagged_user_comments(params[:user_id])}
    end
    render json: {recommends: t_users}
  rescue => e
    rescue_message(e)
  end

  # GET /users/:user_id/recommendations
  def recommendations
    params[:user_id] = BSON::ObjectId.from_string(params[:user_id])
    recommendations = Array.new
    walls = Wall.where("tagged_users.user_id" => params[:user_id])
    if(params[:tag_id].present?)
      walls = walls.where(tag_id: params[:tag_id])
    end
    walls.each do |w|
      tag_name = w.tag_name
      tag_id = w.tag_id.to_s
      rec = w.tagged_user_recommendations(params[:user_id])
      recommendations << {id: rec[:id], tag_id: tag_id, tag_name: tag_name, wall_id: w.id.to_s, comment: rec[:comment], image_url: rec[:image_url], name: rec[:name], user_id: rec[:user_id]}
    end
    render json: {recommendations: recommendations}
  rescue => e
    rescue_message(e)
  end

  # POST /share_sms
  def sms_share
    wall = Wall.find(params[:wall_id])
    # opt = {post_owner: current_user.name, tag_name: wall.tag_name, post_message: wall.message}
    # default_msg =  "#{current_user.name} posted on yelo: #{wall.message.truncate(100)}"
    # str = Notification.message_format("contact_post_msg", opt, default_msg)
    # str += "! Download app at www.yelo.red"
    # str = "#{current_user.name} posted on yelo: #{wall.message.truncate(100)}! Download app at www.yelo.red"
    str = "Your friend #{current_user.name} has asked you for help on #{wall.message.truncate(100)}. Download now bit.ly/yelooo"
    params[:phone_numbers][0..5].each do |s|
       if s =~ Code.phone_regex 
          send_sms_share(s, str)
       end
    end
    render json: {status: "success"}
  end

  def send_sms_share(num, msg)
    number = User.set_mobile_number(current_user, num)
    sms_log = SmsLog.where(mobile_number: number[:mobile_number]).first_or_initialize
    sms_log.country_code = number[:country_code]
    sms_log.last_sms_sent = 1.month.ago
    sms_log.save
    sms_log = sms_log.reload
    sms_log.send_sms(msg)
  end

  # GET /users/claim
  def claim
    statistic = current_user.statistic
    points = statistic.f_r_score
    claim_points = AppSetting.claim_points
    if(points >= claim_points)
      statistic.f_r_score = (points - claim_points)
      statistic.f_r_claims = (statistic.f_r_claims += 1)
      statistic.save
      claim_notification
      render json: {status: "success"}
    else
      render json: {status: "error"}
    end
  end

  def claim_notification
    num = Rails.application.secrets.w_mobile_number
    num = User.mobile_number_format(num) 
    yelo = User.where(mobile_number: num[:mobile_number]).first
    msg = "Your claim has been processed. you will hear from us in a week"
    User.send_chat_message(current_user, yelo, msg)
    User.send_chat_message(yelo, current_user, msg)
    Mailer.claim_mail(current_user).deliver
  end
  
  ############## private methods ###################################
  private

    def save_verified_user
      @user.serial_code = ""
      @user.mobile_verified = true
      @user.push_id = params[:user][:push_id]
      @user.platform = params[:user][:platform]
      @user.utc_offset = params[:user][:utc_offset]
      @user.auth_token = ""
      @user.skip_update_validation =  true
      @user.verify_platform = true
      @user.encrypt_device_id = params[:user][:encrypt_device_id]
      @user.save!
      render json: {id: @user.id.to_s, auth_token: @user.auth_token, is_present: @user.is_present, updated_at: @user.updated_at, share_token: @user.share_token}
    end
    
    def set_mobile_number
      obj = User.mobile_number_format(params[:user][:mobile_number])
      params[:user][:mobile_number] = obj[:mobile_number]
      params[:user][:country_code] =  obj[:country_code]
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :mobile_number, :email, 
        :image, :ext_image_url, :description,
         :platform, :country_code, :ext_image_url, :utc_offset, :push_id, :platform_version)
    end

    def user_create_params
      params.require(:user).permit(:mobile_number, :country_code)
    end

    def existing_user
      @call =  @user.send_missed_call.body
      if(@user.update_attributes(keymatch: @call["keymatch"], serial_code:"", skip_update_validation: true))
        Person.save_person(@user.mobile_number, @user.id, true)
        render json: {status: Code[:status_success], otp_start: @call["otp_start"], call_status: @call["status"]}
      else
        render json: {status: Code[:status_error], error_message: @user.errors.full_messages}, status: Code[:error_code]  
      end
    end

    def create_new_user
      @user = User.new(user_create_params)
      @call =  @user.send_missed_call.body
      @user.keymatch = @call["keymatch"]
      if(@user.save)
        Person.save_person(@user.mobile_number, @user.id, true)
        render json: {status: Code[:status_success], otp_start: @call["otp_start"], call_status: @call["status"]}
      else
        render json: {status: Code[:status_error], error_message: @user.errors.full_messages}, status: Code[:error_code]  
      end
    end
   
    def send_sms
      @sms = @user.send_sms
      if(@sms[:status])
        render json: {status: Code[:status_success]}
      else
        render json: {status: Code[:status_error], error_message: @sms[:error_message]}
      end
    end
end


