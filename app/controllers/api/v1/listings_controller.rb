class Api::V1::ListingsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :user_listings]
  before_action :set_listing, only: [:update]
 
  # POST /listings.json
  def create
    # raise "No more than one listing" if current_user.listings.first.present?
    @listing = current_user.listings.new(listing_params) 
    if(@listing.save)
      @listing.save_keywords(params[:keywords]) if params[:keywords].present?
      @listing.save_links(params[:links]) if params[:links].present?
      render json: @listing
    else
      render json: {error_message: @listing.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
     rescue_message(e)  
  end
 
  # PUT /listings/:id.json
  def update
    @listing.update_attributes(listing_params) if params[:listing].present?
    @listing.save_keywords(params[:keywords]) if params[:keywords].present?
    @listing.save_links(params[:links]) if params[:links].present?
    if(!@listing.errors.present?)
       render json: @listing
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
        :state, :zipcode, :address, :tag_id, :description)
    end

end


