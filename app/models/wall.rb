class Wall
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Geo

  field :message,         type: String
  field :user_id,         type: BSON::ObjectId
  field :tag_user_count,  type: Integer, default: true
  field :tag_id,          type: BSON::ObjectId
  field :chat_users,      type: Array
  field :status,          type: Boolean, default: true
  field :abuse_count,     type: Integer, default: 0
  field :latitude,        type: String
  field :longitude,       type: String
  field :city,            type: String
  field :state,           type: String
  field :country,         type: String
  field :address,         type: String
  field :location,        type: Array
  
  ## relations #######################
  belongs_to  :user, index: true
  belongs_to  :tag,  index: true
  embeds_many :wall_items
  embeds_many :wall_images
  embeds_one  :wall_owner

  ## validators ######################
  validates :message, :city, :country, presence: true

end
