class Share
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :device_id,  type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId

  belongs_to :user
end
