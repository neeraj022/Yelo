class ServiceCard
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id,     type: BSON::ObjectId
  field :listing_id,  type: BSON::ObjectId
  field :tag_id,      type: BSON::ObjectId
  field :tag_name,    type: BSON::ObjectId
  field :title,       type: String
  field :description, type: String
  field :keywords,    type: Array
  field :price,       type: Integer
  field :currency,    type: String
  field :status,      type: Integer, default: 0

  SERVICE_CARD = {OFF: 0,  ON: 1, HIDDEN: 2}
end
