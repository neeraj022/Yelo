class Api::V1::CommentsController <  Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_wall

  # POST /walls/:wall_id/comment  
  def create
    @comment = @wall.comments.new(comment_params.merge(user_id: current_user.id))
    if @comment.save
      render json: @comment
    else
      render json: {error_message: @comment.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
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
     @spam = @comment.comment_spams.where(user_id: current_user.id).first_or_create
     @spam.description = params[:comment][:description]
     if @spam.save
       render json: {status: "success"}
     else
       render json: {error_message: @spam.errors.full_messages}, status: Code[:error_code]
    end
   rescue => e
    rescue_message(e)
   end
  
  def set_Wall
    @wall = Wall.find(params[:wall_id])
  end

  private
    
    def comment_params
      params.require(:comment).permit(:message)
    end

end
