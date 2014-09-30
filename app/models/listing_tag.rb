class ListingTag
  include Mongoid::Document

  field :tag_id,     type: BSON::ObjectId
  field :tag_name,   type: String
  field :rating_id,  type: BSON::ObjectId
  field :rating_avg, type: integer, default: 0
end
