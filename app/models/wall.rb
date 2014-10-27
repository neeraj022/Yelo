class Wall
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Geo
  include WallSearch

  field :message,         type: String
  field :user_id,         type: BSON::ObjectId
  field :tag_id,          type: BSON::ObjectId
  field :tag_name,        type: String
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
  field :chat_user_ids,   type: Array 
  ############### relations #######################
  belongs_to  :user, index: true, touch: true
  belongs_to  :tag,  index: true
  embeds_many :wall_items
  embeds_one  :wall_image
  embeds_one  :wall_owner
  embeds_many :tagged_users
  embeds_one  :wall_info
  ################## filters #######################
  after_create :save_owner_and_statistic
  ################# validators ######################
  validates :message, :city, :country, :tag_id, :latitude, :longitude, presence: true
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  #validate :restrict_wall_creation, on: :create
  validate :tag_presence
  ########### instance methods #######################

  def save_owner_and_statistic
    user = self.user
    user.statistic.last_post = self.created_at
    user.save
    self.create_wall_owner(user_id: user.id, name: user.name, image_url: user.image_url)
  end

  def chat_users_count
    return self.chat_user_ids.length if self.chat_user_ids.present?
    0
  end

  def tag_presence
    if(self.tag_id.present?)
      tag = Tag.where(_id: self.tag_id).first
      if(tag.present?)
        self.tag_name = tag.name
      else
        errors.add(:base, "The given tag id is not present")
      end
    end
  end

  def tagged_users_count
    self.tagged_users.count
  end

  def restrict_wall_creation
    last_post = self.user.statistic.last_post
    if(last_post.present?)
      last_time = Time.now - last_post
      if(last_time < AppSetting.wall_post_interval)
        errors.add(:base, "only one wall post per #{AppSetting.wall_post_interval} seconds")
      end
    end
  end

  def save_image(image)
    self.create_wall_image(image: image)
  end

  def self.save_wall_chat_user(wall_id, user_id)
    wall = Wall.where(_id: wall_id).first
    return false unless wall.present?
    wall.add_to_set(chat_user_ids: user_id)
  end

end
