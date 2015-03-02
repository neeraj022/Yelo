class GcmPing
  include Mongoid::Document

  field :user_id,         type: BSON::ObjectId
end
