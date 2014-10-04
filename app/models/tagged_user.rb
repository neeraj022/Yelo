class TaggedUser
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id,        type: BSON::ObjectId
  field :name,           type: String
  field :image_url,      type: String
  field :email,          type: String
  field :mobile_number,  type: String
  field :up_votes,       type: Integer, default: 0

  ############## relations #############################
  embedded_in :wall

  ################ validators ##########################
  validates :user_id, uniqueness: true, allow_blank: true, allow_nil: true
end
