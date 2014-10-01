class Listing
  include Mongoid::Document

  field :user_id,    type: BSON::ObjectId
  field :status,     type: Boolean, default: true
  field :location,   type: Array
  field :city,       type: String
  field :state,      type: String
  field :country,    type: String
  field :address,    type: String
  ## relations
  belongs_to  :user
  embeds_many :listing_tags

end
