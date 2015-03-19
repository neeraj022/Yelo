class Api::V1::ServiceCardsController < Api::V1::BaseController
  before_action :authenticate_user!

  # POST /service_cards
  def create
  	save_user_doc
  	@listing = current_user.listings.where(_id: params[:listing_id]).first
    @card = ServiceCard.new(service_card_params.merge({user_id: current_user.id, listing_id: params[:listing_id], tag_id: @listing.tag_id}))
    @card.image = params[:image] if params[:image].present?
    if @card.save
      render json: @card
    else
      render json: {error_message: @card.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  # POST /save_user_doc
  def save_user_doc
    if(params[:doc].present?)
      current_user.doc = params[:doc]
      current_user.save
    end
  end
  
  # PUT /service_cards/:id
  def update
  	@card = current_user.service_cards.where(_id: params[:id]).first
    @card.image = params[:image] if params[:image].present?
    if @card.update_attributes(service_card_params)
      render json: @card
    else
      render json: {error_message: @card.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end
  
  # GET /service_cards/:id
  def show
    @card = ServiceCard.find(params[:id])
    render json: @card
  rescue => e
    rescue_message(e)
  end

  # GET /user_service_cards/
  def user_service_cards
    @cards = current_user.service_cards
    render json: @cards
  rescue => e
    rescue_message(e)
  end
  

  # GET /listing_service_cards/:listing_id
  def listing_service_cards
  	@listing = Listing.find(params[:listing_id])
    @cards = @listing.service_cards
    render json: @cards
  rescue => e
    rescue_message(e)
  end

  # DELETE /service_cards/:id
  def destroy
    @card = ServiceCard.find(params[:id])
    @card.destroy
    render json: {status: "success"}
  rescue => e
    rescue_message(e)
  end
  

  private
    
    def service_card_params
      params.require(:service_card).permit(:title, :description, :price, :latitude, :longitude,
      	            :city, :country, :state, :address, :zipcode)
    end

end
