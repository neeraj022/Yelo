class Api::V1::WallItemsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_wall

  def create
    params = wall_item_params.merge(user_id: current_user.id, name: current_user.name, 
                                   image_url: current_user.image_url)
    @wall_item = @wall.wall_items.new(params)
    if(@wall_item.save)
      add_tagged_users
    else
      render json: {error_message: @wall_item.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  def add_tagged_users
    @tagged_users = @wall_item.save_tagged_users(params[:tag_users])
    if(@tagged_users[:status])
      render json: @wall_item
    else
      render json: {error_message: @tagged_users[:error_message]}, status: Code[:error_code]
    end
  end


  private
   
    def wall_item_params
      params.require(:wall_item).permit(:comment, :up_votes, :abuse_count)
    end

    def set_wall
      @wall = Wall.where(_id: params[:wall_id]).first
    end
end
