class Api::V1::WallsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :user_walls]
  before_action :truncate_wall_msg
  before_action :set_wall_params, only: [:create, :update]
  # POST /walls/
  def create
    if (current_user.global_points > 0)
       @wall = current_user.walls.new(wall_params)
       if @wall.save
          @wall.save_image(params[:image]) if params[:image].present?
          #Notification.save_wall(@wall.id.to_s)
          # NewWallWorker.perform_async(@wall.id.to_s)   #new wall interest notifications
          # ContactWallWorker.perform_async(@wall.id.to_s)  #new wall notifications
          # Notification.save_contact_wall(@wall.id)
          current_user.update_attributes(:global_points => current_user.global_points - 5)
          render json: @wall
       else
          render json: {error_message: @wall.errors.full_messages}, status: Code[:error_code]
       end
    else
      render json: {error_message: "Your points are less than 5,so you can not post", status: "success"}
    end
      # rescue => e
      #   rescue_message(e)
  end

  # GET /wall/:id
  def show
    @wall = Wall.where(id: params[:id]).first
    render json: @wall
  end

  # GET /users/:user_id/walls
  def user_walls
    @user = User.where(_id: params[:user_id]).first
    @walls = @user.walls.order("created_at DESC")
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
 
  # POST /walls/:id/close
  def wall_close
    set_mobile_number
    @wall = current_user.walls.where(_id: params[:id]).first
    @wall.status = false
    @wall.is_closed = true
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

  # GET /walls/:id/wall_and_comments
  def wall_and_comments
    @wall = Wall.where(_id: params[:id]).first
    render json: {wall: Code.serialized_json(@wall, "WallCommentSerializer")}
  end

  # GET /walls/chat_users
  def chat_users
    @wall = current_user.walls.where(_id: params[:id]).first
    user_ids = @wall.chat_user_ids
    obj = Array.new
    users = User.where(:_id.in => user_ids) 
    users.each do |u|
      obj << {id: u.id.to_s, name: u.name, image_url: u.image_url}
    end
    render json: {chat_users: obj}
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
      	                           :country, :city, :state, :address, :tmp_id, :group_id, keywords: [])
    end

    def truncate_wall_msg
      params[:wall][:message] =  params[:wall][:message].to_s.truncate(600) if params[:wall].present?
    end

    def set_wall_params
      if(params[:wall][:tag_id].present?)
         params[:wall][:group_id] = Tag.find(params[:wall][:tag_id]).group_id.to_s
      end
      if(params[:wall][:keywords].present?)
        params[:wall][:keywords] = params[:wall][:keywords][0..3]
      end
    end
end
