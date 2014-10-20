class Api::V1::ListingsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :create, :user_listings]
  before_action :set_listing, only: [:update]
 
 # POST /listings.json
  def create
    # raise "No more than one listing" if current_user.listings.first.present?
    @listing = current_user.listings.new(listing_params) 
    if(@listing.save)
      save_tags
    else
      render json: {error_message: @listing.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
     rescue_message(e)  
  end

  def save_tags
    @list_tags_save = @listing.create_tags(params[:tag_ids])
    if @list_tags_save[:status]
       render json: @listing
    else
      render json: {error_message: @list_tags_save[:error_message]}, status: Code[:error_code]
    end
  end
 
 # POST /listings/:id.json
  def update
    if(@listing.update_attributes(listing_params))
      if(params[:tag_ids].present?)
        @listing.listing_tags.destroy
        save_tags
      else
        render json: @listing
      end
    else
      render json: {status: Code[:status_error], error_message: @listing.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

   # GET /users/:id/listings
   def user_listings
     @user = User.where(_id: params[:id]).first
     @listings = @user.listings
     render json: {user: Code.serialized_json(@user, "UserSerializer"), listings: Code.serialized_json(@listings)}
   rescue => e
     rescue_message(e)
   end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_listing
      @listing = current_user.listings.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def listing_params
      params.require(:listing).permit(:latitude, :longitude, :country, :city, 
        :state, :zipcode, :address)
    end

end


