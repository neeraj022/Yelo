class Api::V1::ListingsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :create]
  # POST /listings.json
  def create
  	@listing = Listing.first
    @listing = current_user.listings.new(listing_params) unless @listing.present?
    if @listing.create_with_tags(params[:tag_ids])
      render json: @listing
    else
      render json: {error_message: @listing.errors.full_messages}, status: Code[:status_error]
    end
  rescue => e
     render json: {error_message: e.message}, status: Code[:status_error]
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

    def update_listing_params
      params.require(:listing).permit({sub_cat_ids: []}, 
        :latitude, :longitude, :country, :city, :state, :zipcode, :address)
    end

end
