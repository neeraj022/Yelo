class Api::V1::ServiceCardsController < Api::V1::BaseController
  #before_action :authenticate_user!

  # POST /service_cards
  def create
    current_user = User.find('562f449f7261696096000000')
    unless params[:app_version].blank? && params[:app_type].blank?
        if params[:app_version] >= '56' && params[:app_type] == 'android' || params[:app_version] >= '56' && params[:app_type] == '1'
          @scard = ServiceCard.new(service_card_params.merge({user_id: current_user.id}))
          @scard.image = params[:image] if params[:image].present?
          @scard.app_version = params[:app_version]
          @scard.app_type = params[:app_type]
          @scard.tag_id = params[:tags]
          tag_ids = []
          tags.each do |tag|
            tag_ids << {_id: tag[:tag_id]}
          end
          @scard.tag_id = tag_ids
          if @scard.save
            unless params[:service_card]['avatars'].blank?
              params[:service_card]['avatars'].each do |a|
                @scard.business_images.create!(:avatars => a[:images])
              end
            end
            ServiceCardWorker.perform_async(@scard.id.to_s, "admin", nil)
            scard = {id: @scard.id.to_s,title: @scard.title,description: @scard.description,price: @scard.price,currency: @scard.currency,group_name: "",group_id: "", group_color: "", tag_id: @scard.tag_id.to_s,created_at: @scard.created_at, updated_at: @scard.updated_at, duration_time: "",  }
            render json: @scacd#{data: {service_card: @scard}}
          else
            render json: {error_message: @scard.errors.full_messages}, status: Code[:error_code]
          end
        end
    else
      save_user_doc
      @listing = get_listing.map{}
      puts "get_listing is #{get_listing}"
      @card = ServiceCard.new(service_card_params.merge({user_id: current_user.id}))#, listing_id: @listing.id, tag_id: @listing.tag_id}))
      @card.image = params[:image] if params[:image].present?
      @card.tag_id = params[:tag_id] if params[:tag_id].present?
      @card.listing_id = @listing.id.to_s
      if @card.save
        ServiceCardWorker.perform_async(@card.id.to_s, "admin", nil)
        render json: @card
      else
        render json: {error_message: @card.errors.full_messages}, status: Code[:error_code]
      end
    end
  rescue => e
    puts "e is #{e.backtrace}"
    rescue_message(e)
  end

  def get_listing
    current_user = User.find('562f449f7261696096000000')
    if(params[:listing_id].present?)
      return current_user.listings.where(_id: params[:listing_id]).first
    elsif(params[:tag_id].present?)
     return  find_or_create_listing
    else
      return nil
    end
  end

  def find_or_create_listing
    current_user = User.find('562f449f7261696096000000')
    # tag_ids = params[:tag_id].split(',')
    listing  = []
    listing << current_user.listings.find_or_initialize_by(:tag_id.in  => params[:tag_id].split(','))
    puts "listing is #{listing}"
    listing_ids = []
    listing.each do |list|
      if(!list.persisted?)
        list.l_type = 0
        list.latitude = params[:service_card][:latitude]
        list.longitude =  params[:service_card][:longitude]
        list.save!
      end
      listing_ids << list
    end
    listing_ids
  end

  # GET /service_cards/:id/book/
  def book
    @card = ServiceCard.find(params[:id])
    @card.books = (@card.books += 1)
    @card.save
    @booker = current_user
    @service_book = ServiceCardBook.where(user_id: @booker.id, service_card_id: @card.id)
    @service_book.count = (@service_book.count += 1)
    @service_book.save
    @service_sms_log = ServiceSmsLog.where(user_id: @booker.id, service_card_id: @card.id).first_or_create
    # (+#{@booker.full_mobile_number})
    msg = "#{@booker.name} has booked your service on yelo - #{@card.title}"
    @service_sms_log.send_sms(msg)
    ServiceCardWorker.perform_async(@card.id.to_s, "track", @booker.id.to_s)
    render json: {status: :success}
  rescue => e
    rescue_message(e)  
  end

  # POST /service_cards/:id/views
  def add_views
    ServiceCardView.where(user_id: current_user.id, service_card_id: params[:id]).first_or_create
    render json: {status: :success}
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
    unless params[:app_version].blank? && params[:app_type].blank?
      if params[:app_version] >= '56' && params[:app_type] == 'android' || params[:app_version] >= '56' && params[:app_type] == '1'
        @scard = current_user.service_cards.where(_id: params[:id]).first
        @scard.image = params[:image] if params[:image].present?
        @scard.app_version = params[:app_version]
        @scard.app_type = params[:app_type]
        tags = params[:tags]
        tag_ids = []
        tags.each do |tag|
          tag_ids << {_id: tag[:tag_id]}
        end
        @scard.tag_id = tag_ids
        if @scard.update_attributes(service_card_params)
          params[:service_card]['avatars'].each do |a|
            @scard.business_images.update_attributes!(:avatars => a[:images])
          end
          render json: @scard
        else
          render json: {error_message: @scard.errors.full_messages}, status: Code[:error_code]
        end
      end
    else
      @card = current_user.service_cards.where(_id: params[:id]).first
      @card.image = params[:image] if params[:image].present?
      if @card.update_attributes(service_card_params)
        render json: @card
      else
        render json: {error_message: @card.errors.full_messages}, status: Code[:error_code]
      end
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
    current_user = User.find('562f449f7261696096000000')
    @user = User.where(_id: params[:user_id]).first
    if current_user.id.to_s == params[:user_id]
      @cards = @user.service_cards
    else
      @cards = @user.service_cards.where(status: ServiceCard::SERVICE_CARD[:ON])
      #@cards = @user.service_cards
    end
    render json: @cards
  rescue => e
    puts "exception is #{e.backtrace}"
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
      	            :city, :country, :state, :address, :zipcode, :duration, :duration_unit, :note,business_image_attributes: [:id, :service_card_id_id, :avatars])
    end

end
