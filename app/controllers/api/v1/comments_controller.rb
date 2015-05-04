class Api::V1::CommentsController <  Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_wall

  # POST /walls/:wall_id/comment  
  def create
    @comment = @wall.comments.new(comment_params.merge(user_id: current_user.id))
    if @comment.save
      save_comment_notification
      touch_wall
      render json: @comment
    else
      render json: {error_message: @comment.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  def touch_wall
    @wall.updated_at = Time.now 
    @wall.save
  end

  def save_comment_notification
    return if (@comment.user_id.to_s == @wall.user_id.to_s)
    v_hash = {wall_id: @wall.id.to_s, commented_by: current_user.name, comment: @comment.message}
    notify = Notification.save_notify(Notification::N_CONS[:WALL_COMMENT], v_hash, @wall.user_id)
    notify.send_notification
  end

  # PUT /walls/:wall_id/comment/:id  
  def update
    @comment = @wall.comments.where(_id: params[:id]).first
    if @comment.update_attributes(comment_params)
      render json: @comment
    else
      render json: {error_message: @comment.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

   # DESTROY /walls/:wall_id/comment/:id  
   def destroy
     @comment = @wall.comments.where(_id: params[:id], user_id: current_user.id).first
     @comment.destroy
     render json: {status: "success"}
   end

   # POST /walls/:wall_id/comment/:id/spam 
   def report_spam
     @comment = @wall.comments.where(_id: params[:id]).first
     @comment.spam_count = (@comment.spam_count += 1)
     @spam = @comment.comment_spams.where(user_id: current_user.id).first_or_initialize
     @spam.description = params[:description]
     if @spam.save
       render json: {status: "success"}
     else
       render json: {error_message: @spam.errors.full_messages}, status: Code[:error_code]
    end
   rescue => e
     rescue_message(e)
   end

  private

    def set_wall
      @wall = Wall.find(params[:wall_id])
    end

    def comment_params
      params.require(:comment).permit(:message)
    end

end
