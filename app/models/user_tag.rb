class UserTag
  include Mongoid::Document
  field :tag_id,     type: BSON::ObjectId
  field :user_id,    type: BSON::ObjectId
  field :wall_id,     type: BSON::ObjectId
  field :count,      type: Integer, default: 0
  field :up_votes,   type: Integer, default: 0
  ##################### relations #################################
  belongs_to :user
  has_many :connectors
  ##################### validations ###############################
  validates :tag_id, presence: true
end
