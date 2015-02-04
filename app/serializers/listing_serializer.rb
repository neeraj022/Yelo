class ListingSerializer < CustomSerializer
  attributes :id, :latitude, :longitude, :city, :country, :address, :description, :tag_id, :tag_name, :referral_count,
             :group_name, :group_id
  has_many :listing_keywords
  has_many :listing_links
end
