class Comment
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id,    type: BSON::ObjectId
  field :message,    type: String
  field :status,     type: Integer, default: 1
  field :spam_count, type: Integer, default: 0

  embeds_many :comment_spams
  embedded_in :wall

  validates :user_id, :message, presence: true

  SERVICE_CARD  = {OFF: 0,  ON: 1}
end
