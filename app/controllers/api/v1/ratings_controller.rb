class Api::V1::RatingsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :index]
  before_action :set_user, only: [:index]

  # GET /ratings/:id
  def show
    @rating = Rating.where(_id: params[:id])
    # expires_in 5.minutes, :public => true
    render json: @rating
  rescue => e
    rescue_message(e)
  end

  # POST /ratings
  def create 
    @card = ServiceCard.find(params[:service_card_id])
    @rating = @card.ratings.new(rating_params.merge(reviewer_id: current_user.id, user_id: @card.user_id))
    if(@rating.save)
      render json: @rating
    else
      render json: {status: Code[:status_error], error_message: @rating.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
     rescue_message(e)
  end

  # PATCH/PUT /ratings/:id
  def update
  	@rating = Rating.where(_id: params[:id], reviewer_id: current_user.id).first
    if(@rating.update_attributes(rating_params))
      render json: @rating
    else
      render json: {status: Code[:status_error], error_message: @rating.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  # DELETE /ratings/:id
  def destroy
    @rating = Rating.where(_id: params[:id], reviewer_id: current_user.id).first
    @rating.destroy
    render json: { status: "ok"}
  rescue => e
    rescue_message(e)
  end

  # GET /service_cards/:servcie_card_id/ratings
  def service_card_reviews
    @card = ServiceCard.find(params[:service_card_id])
    if current_user.id.to_s == @card.user_id.to_s
      @ratings = @card.ratings
    else
      @ratings = @card.ratings.where(status: 1)
    end
    render json: @ratings
  rescue => e
    rescue_message(e)
  end

  # POST /ratings/:id/status
  def rating_status
    @rating = Rating.where(_id: params[:id], user_id: current_user.id).first
    @rating.status = params[:status]
    @rating.save
  rescue => e
    rescue_message(e)
   end
  
  private
  
    def set_user
      @user = User.find(params[:user_id])
    end

    def rating_params
      params.require(:rating).permit(:comment, :stars, :tmp_id)
    end
end
