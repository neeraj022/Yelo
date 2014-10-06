class Wall
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Geo
  include WallSearch

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
  field :tag_user_ids,    type: Array 
  ############### relations #######################
  belongs_to  :user, index: true, touch: true
  belongs_to  :tag,  index: true
  embeds_many :wall_items
  embeds_many :wall_images
  embeds_one  :wall_owner
  embeds_many :tagged_users
  ################## filters #######################
  after_create :save_owner_and_statistic
  ################ validators ######################
  validates :message, :city, :country, :tag_id, :latitude, :longitude, presence: true
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validate :restrict_wall_creation, on: :create
  ########### instance methods #######################

  def save_owner_and_statistic
    user = self.user
    user.statistic.last_post = self.created_at
    user.save
    self.create_wall_owner(name: user.name, image_url: user.image_url)
  end

  def restrict_wall_creation
    last_post = self.user.statistic.last_post
    if(last_post.present?)
      last_time = Time.now - last_post
      if(last_time < AppSetting.wall_post_interval)
        errors.add(:base, "only one wall post per #{Code.wall_post_interval} seconds")
      end
    end
  end

  def save_image(image)
   self.wall_images.create(image: image)
  end


end
