class Listing
  include Mongoid::Document

  field :user_id, type: BSON::ObjectId
  field :status,  type: Boolean, default: true
  
  ## relations
  belongs_to  :user
  embeds_many :listing_tags

end
