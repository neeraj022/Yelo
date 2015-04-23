class Api::V1::ServiceCardsController < Api::V1::BaseController
  before_action :authenticate_user!

  # POST /service_cards
  def create
  	save_user_doc
  	@listing = get_listing
    @card = ServiceCard.new(service_card_params.merge({user_id: current_user.id, listing_id: @listing.id, tag_id: @listing.tag_id}))
    @card.image = params[:image] if params[:image].present?
    if @card.save
      ServiceCardWorker.perform_async(@card.id.to_s, "admin", nil)
      render json: @card
    else
      render json: {error_message: @card.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  def get_listing
    if(params[:listing_id].present?)
      return current_user.listings.where(_id: params[:listing_id]).first
    elsif(params[:tag_id].present?)
     return  find_or_create_listing
    else
      return nil
    end
  end

  def find_or_create_listing
    listing = current_user.listings.where(tag_id: params[:tag_id]).first_or_initialize
    if(!listing.persisted?)
      listing.l_type = 0
      listing.latitude = params[:service_card][:latitude]
      listing.longitude =  params[:service_card][:longitude]
      listing.save!
    end
    listing
  end

  # GET /service_cards/:id/book/
  def book
    @card = ServiceCard.find(params[:id])
    @booker = User.find(params[:user_id])
    @service_sms_log = ServiceSmsLog.where(user_id: @booker.id, service_card_id: @card.id).first_or_create
    msg = "#{@booker.name} (#{@booker.full_mobile_number}) has booked your service on yelo - #{@card.title}"
    @service_sms_log.send_sms(msg)
    ServiceCardWorker.perform_async(@card.id.to_s, "track", @booker.id.to_s)
  rescue => e
    rescue_message(e)  
  end

  # POST /save_user_doc
  def save_user_doc
    if(params[:doc].present?)
      current_user.doc = params[:doc]
      current_user.doc_verified = User::USER_CONS[:DOC_SUBMITTED]
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

  # # GET /user_service_cards/
  # def user_service_cards
  #   @cards = current_user.service_cards
  #   render json: @cards
  # rescue => e
  #   rescue_message(e)
  # end

  # GET /users/:user_id/service_cards/
  def user_service_cards
    @user = User.where(_id: params[:user_id]).first
    if current_user.id.to_s == params[:user_id]
      @cards = @user.service_cards
    else
      # @cards = @user.service_cards.where(status: ServiceCard::SERVICE_CARD[:ON])
      @cards = @user.service_cards
    end
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
      	            :city, :country, :state, :address, :zipcode, :duration, :duration_unit, :note)
    end

end
