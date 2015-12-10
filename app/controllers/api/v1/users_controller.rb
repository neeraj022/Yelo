class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:ping, :show, :create, :verify_serial_code, :verify_missed_call, :sms_serial_code, :send_missed_call,:calculate_points]
  before_action :set_mobile_number, only: [:create, :verify_serial_code, :verify_missed_call, :sms_serial_code, :send_missed_call]
  
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
    if current_user.encrypt_device_id == params[:device_id]
      User.register_referral(params[:referral_id], params[:device_id])
      render json: {status: "success"}
    else
       render json: {status: "error", error_message: "wrong device id"}, status: Code[:error_code]  
    end
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
    # current_user.save_contacts_with_name(params[:contacts])
    c_dump = ContactDump.create(user_id: current_user.id, contacts: params[:contacts])
    ContactWorker.perform_async(c_dump.id.to_s)
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

  # GET /users/top_week_recommends
  def top_week_recommends
    today = Time.now
    @users = Wall.collection.aggregate(
     {"$match" => {
        "created_at" => { "$gte" => today.at_beginning_of_week, "$lte" => today.at_end_of_week },
        "status" => true
        }
      }, 
      { "$unwind" => '$wall_items' },
      {
      "$project" => {
          "user_id" => "$wall_items.user_id"
         }
        },
      {"$group" => {
            "_id" => {"user_id" => "$user_id"}, "count" =>  {"$sum" => 1}}
      },
      {
        "$sort" => {"count" => -1}
      },
      { 
        "$limit" => 5 
      }
    )
    @users = User.get_users_and_referral_count(@users)
    render json: {users: @users}
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
      current_user.claim_status.create(number: current_user.mobile_number, amount: claim_points, status: 1)
      claim_notification
      render json: {status: "success", balance: statistic.f_r_score, claims: Code.serialized_json(current_user.claim_status)}
    else
      render json: {status: "error"}, status: Code[:error_code]
    end
  end

  def claim_notification
    num = Rails.application.secrets.w_mobile_number
    num = User.mobile_number_format(num) 
    msg = "Your claim is under process. you will hear from us in a week"
    Code.send_sms(current_user.full_mobile_number, msg)
    ClaimWorker.perform_async(current_user.id.to_s, num[:mobile_number])
  end

  # GET /friend_referral_score
  def friend_referral_score
    score = current_user.statistic.f_r_score
    claims = Code.serialized_json(current_user.claim_status)
    claims = [] unless (claims.kind_of? Array)
    render json: {score: score, claims: claims, minimum_claim: AppSetting.claim_points}
  end

  # POST /users/doc
  def save_doc
    current_user.doc = params[:doc]
    current_user.doc_verified = User::USER_CONS[:DOC_SUBMITTED] if params[:doc].present?
    current_user.save
    render json: {status: "success"}
  end

  # POST /send_missed_call
  def send_missed_call
    @user = User.where(mobile_number: params[:user][:mobile_number]).first
    if(@user.present?)
      @call = @user.send_missed_call.body
      @user.keymatch = @call["keymatch"]
      @user.save
      render json: {status: Code[:status_success], otp_start: @call["otp_start"], call_status: @call["status"]}
    else
      render json: {error_message: "user not present"}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end
 
  def chat_users #listing of users for chat initialization
    @user =  User.where(_id: params[:id]).first
    if @user.present?
      @yelo = User.find("54595a2779656c42fb000000")
      @yelo_usr = [id:@yelo.id.to_s,name:@yelo.name,image_url: @yelo.image.url] if @yelo.present?
      #@recent_users = @user.chat_logs.map{|c|c.chatter_id.to_s}.uniq
      #@rec_usr = User.find(@recent_users) unless @recent_users.blank?
      #@recent_user =  @rec_usr.map{|e|{name: e.name,id:e.id.to_s,image_url:e.image.url}} unless @rec_usr.blank?
      person = []
      unless @user.contacts.blank?
        @user.contacts.each do |c|
          unless c.person.blank?
            if c.person.is_present
               person << c.person
            end
          end
        end
      end
      ids = person.map{|p|p.user_id.to_s}
      @dev_usr = User.find(ids) unless ids.blank?
      @device_contact = @dev_usr.map{|e|{name: e.name,id:e.id.to_s,image_url:e.image.url}} unless @dev_usr.blank?
      render json: {status: "success",:data => {yelo: @yelo_usr, recent_users: [], device_contact: @device_contact.blank? ? [] : @device_contact.sort_by{|arr|arr[:name]}}}

    else
      render json: {error_message: "user not present"}, status: Code[:error_code]
    end
  end
  
  def calculate_points
    @walls = Wall.all.to_a
    user_ids = @walls.collect{|i|i.wall_items.collect{|u|u.user_id.to_s}}.flatten
    usr_ids = @walls.collect{|c|c.comments.collect{|uu|uu.user_id.to_s}}.flatten
    @users = User.all.to_a
    a = []
    @users.each do |user|
      b = {}
      b[:id] = user.id.to_s
      b[:name] = user.name
      b[:refer_point] = (user_ids.count(user.id.to_s))*10
      b[:comment_point] = (usr_ids.count(user.id.to_s))*5
      b[:ask_point] = user.walls.count*-5
      b[:total_points] = (user_ids.count(user.id.to_s))*10 + (usr_ids.count(user.id.to_s))*5 + user.walls.count*-5
      if (b[:total_points] < 100)
        user.update_attributes(:global_points => 100)
      else
        user.update_attributes(:global_points => b[:total_points])
      end
      a << b
    end
    render json: {status: "success",:data => {:global_points => a}}
  end

  def leaderboard
    @users = paginate User.desc(:global_points).limit(50).collect{|c|{id:c.id.to_s,name:c.name,image_url:c.image.url,global_points:c.global_points}}, per_page: 10
    unless @users.blank?
      render json: {status: '1',:message => 'Records',:data => {global_users: @users, pages: 50/10}}
    else
      render json: {:status => '1',:message => 'No records found',:data => {global_users: [], pages: 50/10}}
    end
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
      if(@user.update_attributes(serial_code:"", skip_update_validation: true))
        Person.save_person(@user.mobile_number, @user.id, true)
        @user = @user.reload
	walls = Wall.all.to_a
        user_ids = walls.collect{|i|i.wall_items.collect{|u|u.user_id.to_s}}.flatten
        refer_point = (user_ids.count(@user.id.to_s))*10
        usr_ids = walls.collect{|c|c.comments.collect{|uu|uu.user_id.to_s}}.flatten
        comment_point = (usr_ids.count(@user.id.to_s))*5
        wall = @user.walls
        ask_point = wall.count*-5
        total_points = refer_point +  comment_point + ask_point
        if total_points < 100
          @user.update_attributes(:global_points => 100)
        else
          @user.update_attributes(:global_points => total_points)
        end
        send_sms
      else
        render json: {status: Code[:status_error], error_message: @user.errors.full_messages}, status: Code[:error_code]  
      end
    end

    def create_new_user
      @user = User.new(user_create_params)
      if(@user.save)
	@global_points = @user.update_attributes(:global_points => 100)
        @sms = @user.send_sms
        Person.save_person(@user.mobile_number, @user.id, true)
        render json: {status: Code[:status_success]}
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


