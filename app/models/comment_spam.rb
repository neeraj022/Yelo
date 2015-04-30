class CommentSpam
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id,       type: BSON::ObjectId
  field :description,   type: String

  embedded_in :comment

  validates :user_id, presence: true
end
