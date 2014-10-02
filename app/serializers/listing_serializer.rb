class ListingSerializer < CustomSerializer
  attributes :id
  has_many :listing_tags
end
