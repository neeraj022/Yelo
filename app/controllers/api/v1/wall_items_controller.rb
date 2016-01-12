class Api::V1::WallItemsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_wall

  def create
    params = wall_item_params.merge(user_id: current_user.id, name: current_user.name, 
                                   image_url: current_user.image_url)
    render json: {error_message:{mobile_number: ["Wall is already closed"]}}, status: Code[:error_code] and return  if @wall.is_closed?
    @wall_item = @wall.wall_items.new(params)
    if(@wall_item.save)
      add_tagged_users
    else
      render json: {error_message: @wall_item.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
   # @wall_item.destroy if @wall.is_closed?
   @wall_item.destroy if @wall_item.persisted?
    rescue_message(e)
  end

  def add_tagged_users
    @tagged_users = @wall_item.save_tagged_users(params[:tag_users])
    current_user.update_attributes(:global_points => current_user.global_points + 10)
    if(@tagged_users[:status])
     # current_user.update_attributes(:global_points => current_user.global_points + 10)
      render json: @wall_item
    else
      @wall_item.destroy
      render json: {error_message: @tagged_users[:error_message]}, status: Code[:error_code]
    end
  end

  # DELETE walls/:wall_id/wall_items/:id
  def destroy
    @wall = Wall.where(_id: params[:wall_id]).first
    @wall_item = @wall.wall_items.where(_id: params[:id], user_id: current_user.id.to_s).first
    @wall.tagged_users.where(:_id.in => @wall_item.tagged_user_ids).destroy
    @wall_item.destroy
    render json: { status: "success"}
  rescue => e
    rescue_message(e)
  end

  private
   
    def wall_item_params
      params.require(:wall_item).permit(:comment, :up_votes, :abuse_count, :tmp_id)
    end

    def set_wall
      @wall = Wall.where(_id: params[:wall_id]).first
    end
end
