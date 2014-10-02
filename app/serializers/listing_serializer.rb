class ListingSerializer < CustomSerializer
  attributes :id, :latitude, :longitude, :city, :country
  has_many :listing_tags
end
