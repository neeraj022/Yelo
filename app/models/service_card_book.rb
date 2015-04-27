class ServiceCardBook
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id,       type: BSON::ObjectId
  field :count,         type: Integer, default: 0

  belongs_to :service_card
end
