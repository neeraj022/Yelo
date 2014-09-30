class Listing
  include Mongoid::Document

  field :user_id, type: BSON::ObjectId
  
  belongs_to  :user
  embeds_many :listing_tags
end
