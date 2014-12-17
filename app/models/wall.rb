class Wall
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Geo
  include WallSearch
  include Common

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
  # field :tag_user_ids,    type: Array
  field :chat_user_ids,   type: Array 
  field :is_indexed,      type: Boolean, default: false
  field :is_closed,       type: Boolean, default: false
  field :is_abuse,        type: Boolean, default: false
  ############### relations #######################
  belongs_to  :user, index: true, touch: true
  belongs_to  :tag,  index: true
  embeds_many :wall_items
  embeds_one  :wall_image
  embeds_one  :wall_owner
  embeds_many :tagged_users
  embeds_one  :wall_info
  has_many :report_abuses, as: :abuse_obj
  ################## filters #######################
  before_create :save_owner_and_statistic
  after_create :set_index_status
  ################# validators ######################
  validates :message, :city, :country, :tag_id, :latitude, :longitude, presence: true
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  # validate :restrict_wall_creation, on: :create
  validate :tag_presence
  ####################### scopes ############################
  scope :allowed, -> { where(status: true) }
  ########### instance methods #######################

  def save_owner_and_statistic
    user = self.user
    user.statistic.last_post = self.created_at
    user.save
    self.build_wall_owner(user_id: user.id, name: user.name, image_url: user.image_url)
  end

  def chat_users_count
    return self.chat_user_ids.length if self.chat_user_ids.present?
    0
  end

  def set_index_status
    self.is_indexed = true
    self.save
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

  def get_tagged_users
    users = Array.new
    self.tagged_users.each do |t|
      users << {id: t.user_id.to_s, name: t.name, mobile_number: t.mobile_number,  image_url: t.image_url}
    end
    users
  end

  def save_image(image)
    self.create_wall_image(image: image)
  end

  def self.save_wall_chat_user(wall_id, user_id)
    wall = Wall.where(_id: wall_id).first
    return false unless wall.present?
    wall.add_to_set(chat_user_ids: user_id)
  end

  def tagged_user_comments(user_id)
    users = Hash.new
    self.wall_items.where(user_id: user_id).each do |i|
      users[:comment] = i.comment
      tg = i.tagged_users.first
      users[:name] = tg.name
      users[:image_url] = tg.image_url
    end
    users
  end

  def tagged_user_recommendations(user_id)
    tg_id = self.tagged_users.where(user_id: user_id).first.id.to_s
    wall_item = self.wall_items.where(:tagged_user_ids  => tg_id).first
    {comment: wall_item.comment, image_url: wall_item.image_url}
  end

  def abuse(user_id)
    abuse = self.report_abuses.where(user_id: user_id).first
    if(abuse.blank?)
      abuse = self.report_abuses.create(user_id: user_id)
      self.abuse_count = (self.abuse_count += 1)
      if self.abuse_count >= AppSetting.max_abuse_count 
        self.status = false
        self.is_abuse = true
      end
      self.save
    else
      false
    end
  end

end
