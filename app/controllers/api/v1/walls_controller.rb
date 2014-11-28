class Api::V1::WallsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :user_walls]

  # POST /walls/
  def create
    @wall = current_user.walls.new(wall_params)
    if @wall.save
      @wall.save_image(params[:image]) if params[:image].present?
      # Notification.save_wall(@wall.id.to_s)
      NewWallWorker.perform_async(@wall.id.to_s)
      ContactWallWorker.perform_async(@wall.id.to_s)
      # Notification.save_contact_wall(@wall.id)
      render json: @wall
    else
      render json: {error_message: @wall.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  # GET /wall/:id
  def show
    @wall = Wall.where(id: params[:id]).first
    render json: @wall
  end

  # GET /users/:user_id/walls
  def user_walls
    @user = User.where(_id: params[:user_id]).first
    @walls = @user.walls.allowed.order("created_at DESC")
    render json: @walls
  rescue => e
    rescue_message(e)
  end
  
  # POST /walls/:id
  def update
    @wall = current_user.walls.where(_id: params[:id]).first
    if @wall.update_attributes(wall_params)
      @wall.save_image(params[:image]) if params[:image].present?
      render json: @wall
    else
      render json: {error_message: @wall.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
  	rescue_message(e)
  end

  # DELETE /walls/:id 
  def destroy
    @wall = current_user.walls.where(_id: params[:id]).first
    @wall.destroy
    render json: { status: "success"}
  rescue => e
    rescue_message(e)
  end
  
  # GET /walls/:id/connects
  def connects
    @wall = Wall.where(_id: params[:id]).first
    tag_users = @wall.get_tagged_users()
    chat_users = User.get_users(@wall.chat_user_ids)
    render json: {tag_users: tag_users, chat_users: chat_users}
  rescue => e
    rescue_message(e)
  end
 
  # post /walls/:id/close
  def wall_close
    set_mobile_number
    @wall = current_user.walls.where(_id: params[:id]).first
    @wall.status = false
    @wall_info = @wall.build_wall_info(is_solved: params[:is_solved], s_name: params[:name], s_mobile_number: 
    @mobile_number, s_user_id: params[:user_id], s_country_code: @country_code)
    if(@wall.save)
      render json: {status: "success"}
    else
      render json: {error_message: @wall.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end
  
  private
  
    def set_mobile_number
      obj = User.mobile_number_format(params[:mobile_number]) if params[:mobile_number].present?
      obj ||= {}
      @mobile_number = (obj[:mobile_number] ||= "")
      @country_code =  (obj[:country_code] ||= "")
    end

    def wall_params
      params.require(:wall).permit(:tag_id, :message, :latitude, :longitude,
      	                           :country, :city, :state, :address, :tmp_id)
    end

end
