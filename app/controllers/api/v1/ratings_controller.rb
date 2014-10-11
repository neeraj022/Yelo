class Api::V1::RatingsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :index]
  before_action :set_user, only: [:show, :create, :index]

  # GET /users/:user_id/ratings
  def index
    @ratings = @user.ratings
    # expires_in 5.minutes, :public => true
    render json: @ratings
  rescue => e
    rescue_message(e)
  end

  # GET /users/:user_id/ratings/:id
  def show
    @rating = @user.ratings.where(_id: params[:id])
    # expires_in 5.minutes, :public => true
    render json: @rating
  rescue => e
    rescue_message(e)
  end

  # POST /users/:user_id/ratings
  def create 
    @rating = @user.ratings.new(rating_params.merge(reviewer_id: current_user.id))
    @rating.create_rating_owner(user_id: current_user.id, name: current_user.name, image_url: current_user.image_url)
    if(@rating.save)
      @rating.save_tags(params[:tag_ids]) if params[:tag_ids].present?
      render json: @rating
    else
      render json: {status: Code[:status_error], error_message: @rating.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
     rescue_message(e)
  end

  # PATCH/PUT /users/:user_id/ratings/:id
  def update
  	@rating = current_user.ratings.find(params[:id])
    if(@rating.update_attributes(rating_params))
      @rating.rating_tags.destroy && @rating.save_tags(params[:tag_ids]) if params[:tag_ids].present?
      render json: @rating
    else
      render json: {status: Code[:status_error], error_message: @rating.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  # DELETE /users/:user_id/ratings/:id
  def destroy
    @rating = current_user.ratings.find(params[:id])
    @rating.destroy
    render json: { status: "ok"}
  rescue => e
    rescue_message(e)
  end

  private
  
  def set_user
    @user = User.find(params[:user_id])
  end

  def rating_params
    params.require(:rating).permit(:comment, :stars)
  end
end
