class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :create, :verify_serial_code]
  before_action :set_mobile_number, only: [:create, :update, :verify_serial_code]
  
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
    expires_in 5.minutes, :public => true
    render json: @user
  rescue => e
    rescue_message(e)
  end

  # POST /verify
  def verify_serial_code
    @user = User.where(mobile_number: params[:user][:mobile_number], serial_code: params[:user][:serial_code]).first
    if(@user.present?)
      @user.serial_code = ""
      @user.push_id = params[:user][:push_id]
      @user.platform = params[:user][:platform]
      @user.auth_token = ""
      @user.serial_present =  true
      @user.encrypt_device_id = params[:user][:encrypt_device_id]
      @user.save!
      render json: {auth_token: @user.auth_token, is_present: @user.is_present}
    else
      render json: {auth_token: ""}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end
  
  ## private methods ###################################
  private
    def set_mobile_number
      obj = User.mobile_number_format(params[:user][:mobile_number])
      params[:user][:mobile_number] = obj[:mobile_number]
      params[:user][:country_code] =  obj[:country_code]
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :mobile_number, :email, 
        :image, :ext_image_url, :description, :encrypt_device_id, :push_token,
         :platform, :country_code, :ext_image_url)
    end

    def user_create_params
      params.require(:user).permit(:mobile_number, :country_code)
    end

   def existing_user
     if(@user.update_attributes(user_create_params.merge(serial_code: "",
               encrypt_device_id: params[:user][:encrypt_device_id])))
       render json: {status: Code[:status_success]}
     else
       render json: {status: Code[:status_error], error_message: @user.errors.full_messages}, status: Code[:error_code]  
     end
   end

  def create_new_user
    @user = User.new(user_create_params)
    if(@user.save)
      render json: {status: Code[:status_success]}
    else
      render json: {status: Code[:status_error], error_message: @user.errors.full_messages}, status: Code[:error_code]  
    end
  end
end
