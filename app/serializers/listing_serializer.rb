class ListingSerializer < CustomSerializer
  attributes :id, :latitude, :longitude, :city, :country, :address
  has_many :listing_tags
end
