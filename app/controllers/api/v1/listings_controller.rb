class Api::V1::ListingsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:show, :create]
  # POST /listings.json
  def create
  	raise "No more than one listing" if Listing.first.present?
    @listing = current_user.listings.new(listing_params) 
    if(@listing.save)
      @list_save = @listing.create_tags(params[:tag_ids])
      raise "Listing saved but error with tags #{@l_tag[:error_message]}" unless @list_save[:status]
      render json: @listing
    else
      render json: {error_message: @listing.errors.full_messages}, status: Code[:error_code]
    end
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

    def update_listing_params
      params.require(:listing).permit({sub_cat_ids: []}, 
        :latitude, :longitude, :country, :city, :state, :zipcode, :address)
    end

end
