class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :create, :verify_serial_code, :verify_missed_call, :sms_serial_code]
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

  # GET /users/:user_id/recommends/tags
  def tag_recommends
    params[:user_id] = BSON::ObjectId.from_string(params[:user_id])
    @tag_obj = Wall.collection.aggregate(
         {
          "$match" => { "wall_items.user_id" => params[:user_id]} 
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
  end

  # GET /users/:user_id/recommends
  def recommends
    params[:user_id] = BSON::ObjectId.from_string(params[:user_id])
    t_users = Hash.new
    walls = Wall.where("wall_items.user_id" => params[:user_id])
    if(params[:tag_id].present?)
      walls = walls.where(tag_id: params[:tag_id])
    end
    walls.each do |w|
      tag_name = w.tag_name
      h_obj = (t_users[tag_name.to_sym] ||= Array.new)
      h_obj << {wall_id: w.id.to_s, tagged_users: w.tagged_user_comments}
    end
    render json: {recommends: t_users}
  rescue => e
    rescue_message(e)
  end

  # GET /users/:user_id/recommendations
  def recommendations
    params[:user_id] = BSON::ObjectId.from_string(params[:user_id])
    recommendations = Hash.new
    walls = Wall.where("tagged_users.user_id" => params[:user_id])
    if(params[:tag_id].present?)
      walls = walls.where(tag_id: params[:tag_id])
    end
    walls.each do |w|
      tag_name = w.tag_name
      h_obj = (recommendations[tag_name.to_sym] ||= Array.new)
      h_obj << {wall_id: w.id.to_s, comments: w.tagged_user_recommendations(params[:user_id])}
    end
    render json: {recommendations: recommendations}
  rescue => e
    rescue_message(e)
  end
  
  ## private methods ###################################
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
      # @sms = @user.send_sms
      # if(@sms[:status])
        key = Code.encrypt_aes(@user.serial_code.to_s)
        # serial_code: key[2]
        render json: {status: Code[:status_success], serial_code: key[2]}
      # else
      #   render json: {status: Code[:status_error], serial_code: @user.serial_code, error_message: @sms[:error_message]}
      # end
    end
end


