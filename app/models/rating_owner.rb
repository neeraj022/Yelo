class RatingOwner
  include Mongoid::Document
  field :image_url,    type: String
  field :name,         type: String
  field :user_id,      type: BSON::ObjectId
  ########### relations ##################
  embedded_in :rating

end