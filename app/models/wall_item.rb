class WallItem
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id,          type: BSON::ObjectId
  field :comment,          type: String
  field :tg_usr_id,        type: BSON::ObjectId
  field :tg_usr_name,      type: String
  field :tg_usr_img_url,   type: String
  field :image_url,        type: String
  field :up_votes,         type: Integer, default: true
  field :name,             type: String
  field :abuse_count,     type: Integer, default: 0
  
  ## validators ###############
  validates :user_id, :tag_user_id, presence: true
  validates :tag_usr_id,  uniqueness: true

end
