class RatingTag
  include Mongoid::Document
  field :tag_id,     type: BSON::ObjectId
  field :tag_name,   type: String
  ############ relations #################
  embedded_in :rating
end
