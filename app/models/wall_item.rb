class WallItem
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id,          type: BSON::ObjectId
  field :comment,          type: String
  field :image_url,        type: String
  field :up_votes,         type: Integer, default: 0
  field :name,             type: String
  field :abuse_count,      type: Integer, default: 0
  field :tag_user_ids,     type: 
  ############### validators ###############
  validates :user_id,  presence: true

end
