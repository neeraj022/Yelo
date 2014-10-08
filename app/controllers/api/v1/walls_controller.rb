class Api::V1::WallsController < Api::V1::BaseController
  before_action :authenticate_user!

  # POST /walls/
  def create
    @wall = current_user.walls.new(wall_params)
    if @wall.save
      @wall.save_image(params[:image]) if params[:image].present?
      # NotificationWorker.perform_async({type: "wall_create", wall_id: @wall.id.to_s})
      Notification.save_wall(@wall.id.to_s)
      render json: @wall
    else
      render json: {error_message: @wall.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end
  
  # POST /walls/:id
  def update
    @wall = current_user.walls.where(_id: params[:id]).first
    if @wall.update_attributes(wall_params)
      render json: @wall
    else
      render json: {error_message: @wall.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
  	rescue_message(e)
  end
  
  
  private
    def wall_params
      params.require(:wall).permit(:tag_id, :message, :latitude, :longitude,
      	                           :country, :city, :state, :address)
    end

end
