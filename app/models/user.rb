require 'open-uri'
class User
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Geo  
  include Common
  # include UserSearch
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  attr_accessor :skip_update_validation, :verify_platform
  
  ## Database authenticatable
  field :mobile_number,        type: Integer, default: ""
  field :name,                 type: String
  field :description,          type: String
  field :platform,             type: String
  field :encrypt_device_id,    type: String
  field :push_id,              type: String
  field :country_code,         type: Integer
  field :email,                type: String, default: ""
  field :encrypted_password,   type: String, default: ""
  field :avatar_off,           type: String, default: false
  field :interest_ids,         type: Array 
  field :status,               type: Boolean, default: true
  field :abuse_count,          type: Boolean, default: 0 
  field :is_admin,             type: Boolean, default: false  
  field :serial_code,          type: Integer
  field :sms_verified,         type: Boolean, default: false
  field :call_verified,        type: Boolean, default: false
  field :mobile_verified,      type: Boolean, default: false
  field :auth_token,           type: String
  field :share_token,          type: String
  field :ext_image_url,        type: String
  field :location,             type: Array
  field :city,                 type: String
  field :state,                type: String
  field :country,              type: String
  field :is_present,           type: Boolean, default: false
  field :latitude,             type: String
  field :longitude,            type: String
  field :last_notify_sent_at,  type: String
  field :utc_offset,           type: Integer, default: 0
  field :keymatch,             type: String
  field :w_msg_sent,           type: Boolean, default: false
  field :h_m_num,              type: String
  field :platform_version,     type: String
  field :admin_type,           type: Integer, default: 0
  field :doc_verified,         type: Integer, default: 0
  field :is_service,           type: Boolean, default: false
  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time
 
  ################# index #######################
  index "mobile_number" => 1
  index "auth_token" => 1
  ############## carrier wave ######################
  mount_uploader :image, ImageUploader
  mount_uploader :doc, DocUploader
  ############## relations #########################
  has_many :listings, dependent: :destroy
  has_many :walls, dependent: :destroy     
  embeds_one :setting
  embeds_one :statistic
  has_many :user_tags, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :chat_logs, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :connects, class_name: "Connector"
  embeds_many :contacts
  has_one :people
  has_many :shares
  has_many :claim_status
  has_many :service_cards
  ############## filters ############################
  before_save :ensure_authentication_token, :mobile_verification_serial
  after_save :update_embed_docs
  before_create :ensure_share_token
  before_validation :ensure_password
  after_create :ensure_statistic_and_setting
  ############## validators #########################
  validates :mobile_number, presence: true,
                      numericality: true,
                      uniqueness: true,
                      length: { is: 10 }
  validates :country_code, presence: true, numericality: true
  validates :email, uniqueness: true, allow_blank: true, allow_nil: true
  validates :platform, :encrypt_device_id,
             presence: true, on: :update, :if => lambda { |u| u.validate_profile? || u.validate_platform? }
  validates :name, presence: true, on: :update, :if => :validate_profile?
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }, allow_blank: true, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_blank: true, allow_nil: true
  ####################### scopes ############################
  scope :allowed, -> { where(status: true, mobile_verified: true) }
  ##################### cons ######################################
  USER_CONS = {DOC_SUBMITTED: 1,  DOC_VERFIED: 2, NO_DOC: 0}
  ##################### instance methods ##########################
  def tags
    tags = Array.new
    self.listings.each do |l|
      l.listing_tags.each{|t| tags << {id: t.tag_id.to_s ,name: t.tag_name}}
    end
    tags
  end

  def all_tags
    {listing_tags: tags, interest_tags: interest_tags}
  end

  def interest_tags
    ids = self.interest_ids ||= []
    tags = Tag.where(:_id.in => ids)
    arr = tags.map{|t| {id: t.id.to_s, name: t.name}}
    arr
  end

  def wall_tags
    self.interest_ids.concat(self.tags.map{|t| t[:id]})
  end

  def alert_notify
    obj = {collapse_key: "alert", message: "", resource: {name:
      "chat alert", dest: ""}}
    Notification.push_notify(self.platform, [self.push_id], obj)
  end

  def connects_count
    self.statistic.connects
  end

  def validate_profile?
    self.skip_update_validation ? false : true
  end

  def validate_platform?
    self.verify_platform ? true : false
  end

  def online?
    updated_at > 5.minutes.ago
  end

  def m_call_token
    Rails.application.secrets.m_call_token
  end
  
  def m_call_id
    Rails.application.secrets.m_call_id
  end

  def send_missed_call
    Unirest.get "https://www.cognalys.com/api/v1/otp/?access_token=#{self.m_call_token}&app_id=#{self.m_call_id}&mobile=#{self.full_mobile_number}"
  end

  def verify_missed_call(m_call_num)
    Unirest.get"https://www.cognalys.com/api/v1/otp/confirm/?access_token=#{self.m_call_token}&app_id=#{self.m_call_id}&otp=#{m_call_num}&keymatch=#{self.keymatch}"
  end
  
  def save_rating_and_score
    rating = get_rating_and_users_count
    avg = rating[:avg]
    user_count = rating[:user_count]
    self.statistic.rating_avg = avg
    self.statistic.rating_score = (avg * user_count)
    self.save
  end

  def rating_avg
    self.statistic.rating_avg
  end

  def total_tagged
    self.user_tags.count
  end

  def total_ratings
    self.ratings.count
  end

  def get_rating_and_users_count
    ratings_array = self.ratings.where(:"stars".gt => 0)
    count = ratings_array.count
    sum = ratings_array.sum(:stars) 
    avg = (sum/count)*100/100
    {avg: avg, user_count: count}
  end

  def save_user_tags(tag_id, tagged_by)
    user_tag = self.user_tags.where(tag_id: tag_id).first
    unless user_tag.present?
      user_tag = self.user_tags.create(tag_id: tag_id)
    end
    user_tag.connectors.where(user_id: tagged_by).first_or_create
    user_tag.count = user_tag.count += 1
    user_tag.save
    user_tag
  end
  
  def ensure_statistic_and_setting
    self.create_statistic
    self.create_setting
  end

  def send_sms
    statistic = self.statistic
    last_sms_date = statistic.last_sms_sent.to_date if statistic.last_sms_sent.present?
    last_sms_date ||= 1.month.ago.to_date
    present_date = Time.now.to_date
    if(last_sms_date == present_date)
      if(AppSetting.sms_per_day >= statistic.sms_count)
        statistic.sms_count = statistic.sms_count += 1
        statistic.save
        return {status: true, response: self.sms}
      else
        msg = "only #{AppSetting.sms_per_day} verfication sms per day"
        return {status: false, error_message: msg}
      end
    else
      statistic.last_sms_sent = Time.now
      statistic.sms_count = 0
      statistic.save
      return {status: true, response: self.sms}
    end
  end

  def sms
    msg = "yelo verification code: #{self.serial_code}"
    res = Code.send_sms(self.full_mobile_number, msg)
  end

  def full_mobile_number
    self.country_code.to_s + self.mobile_number.to_s
  end

  # for devise remove email validation
  def email_required?
    false
  end

  # for devise remove email validation
  def email_changed?
    false
  end

  # for mongoid $oid issue with session serialization
  def self.serialize_from_session(key, salt)
    record = to_adapter.get(key[0]['$oid'])
    record if record && record.authenticatable_salt == salt
  end

  def image_url
    if !Rails.application.secrets.cloud_storage.present? || self.image.url.include?("fallback")
      Rails.application.secrets.app_url+self.image.url
    else
      self.image.url
    end
  end

  def profile_image
    if  self.image.blank? || self.image.url.include?("fallback")
      false
    else
      true
    end
  end

  def mobile_number_filter
    if mobile_number_changed? && mobile_number.length > 10
      num =  self.mobile_number
      self.mobile_number = num.slice!(-(10-num.length), 10)
      self.country_code = num
    end
  end

  def ensure_authentication_token
    if auth_token.blank?
      self.auth_token = generate_authentication_token
    end
  end

  def ensure_share_token
    return if share_token.present?
    self.share_token = Devise.friendly_token
  end

  def mobile_verification_serial
    if serial_code.blank?
      self.serial_code = SecureRandom.random_number.to_s[2..7]
    end
  end

  def ensure_password
    return if self.encrypted_password.present?
    self.password = Devise.friendly_token
  end

  def can_send_notification?(type)
    n_setting  = self.notify_setting
    case n_setting
    when Setting::NS_CODE[:NOTIFY_ALL]
      return true
    when Setting::NS_CODE[:NOTIFY_MUTE]
      return false
    when Setting::NS_CODE[:NOTIFY_SUMMARY]
      return true if is_instant(type)
    else
      return true
    end
  end

  def is_instant(type)
    case type
    when Notification::N_CONS[:USER_TAG]
      return true
    when Notification::N_CONS[:WALL_PIN]
      return true
    when Notification::N_CONS[:CONTACT_WALL]
      return true
    when Notification::N_CONS[:CREATE_WALL]
      return true
    else
      return false
    end
  end

  def notify_setting
    setting = self.setting
    return setting.ns_code if setting.present?
    Setting::NS_CODE[:NOTIFY_ALL]
  end

  def can_send_summary_notification?
    diff_time = notify_time_diff
    interval = AppSetting.summary_notify_interval
    utc_offset = (self.utc_offset ||= 0)
    c_user_hour = Code.utc_time(utc_offset).hour
    c_user_hour <= 15 && c_user_hour >= 11 && (diff_time >= interval)
  end

  def notify_time_diff
    c_time = Time.now.to_i
    n_time = self.last_notify_sent_at
    return 0 if n_time.blank?
    n_time = Time.parse(self.last_notify_sent_at).to_i
    diff = ((c_time - n_time) / 3600).ceil
  end
  
  def update_embed_docs
    if(name_changed? || image_changed?)
      wall_owner_update
      rating_owner_update
    end
  end

  def wall_owner_update
    walls = self.walls
    walls.each do |w|
      save_owner(w)
    end
  end

  def rating_owner_update
    ratings = Rating.where(reviewer_id: self.id.to_s)
    ratings.each do |r|
      save_owner(r)
    end
  end

  def save_owner(obj)
    owner = obj.wall_owner
    owner.name = self.name 
    owner.image_url = self.image_url if image_changed?
    owner.save
  end

  def save_contacts(numbers)
    m_num = Person.get_number_digest(self.mobile_number.to_s)
    numbers.each do |n|
      next if m_num == n
      p = Person.where(h_m_num: n).first_or_create
      save_friend(p) if p.persisted?
    end
  end

  def save_contacts_with_name(c_array)
    m_num = Person.get_number_digest(self.mobile_number.to_s)
    c_array.each do |n|
      next if m_num == n["hash_mobile_number"]
      p = Person.where(h_m_num: n["hash_mobile_number"]).first_or_create
      save_friend(p) if p.persisted?
      p.c_names.create(name: n["name"], user_id: self.id)
    end
  end

  def save_friend(p)
    self.contacts.create(person_id: p.id)
  end

  def app_contacts
    contact_ids = self.contacts.map{|c| c.person_id}
    persons = Person.where(:_id.in => contact_ids, is_present: true)
    user_ids = persons.map{|p| p.user_id}.compact
    users = User.allowed.where(:_id.in => user_ids)
  end

  def send_welcome_message
    id = self.id.to_s
    num = Rails.application.secrets.w_mobile_number
    num = User.mobile_number_format(num) 
    sender = User.where(mobile_number: num[:mobile_number]).first
    w_message = "Hey #{self.name}!\n"+AppSetting.welcome_chat_message
    chat_url = Rails.application.secrets.chat_url
    str = "?sender_id=#{sender.id.to_s}&receiver_id=#{id}&message=#{w_message}&sent_at=#{Time.now.to_s}"
    token = 'Token token='+"\""+sender.auth_token+"\""+","+' device_id='+"\""+sender.encrypt_device_id+"\""
    Unirest.post"#{chat_url}/api/v1/chats/send/#{str}", headers: {"Authorization" => token}
    rescue => e
      false
   end
  ################# class methods ###########################
  class << self
    
    def mobile_number_format(num)
      num = num.to_s.sub(/^\+*0+/, "")
      mobile_number = num.slice!(-(10-num.length), 10)
      {mobile_number: mobile_number, country_code: num}
    end
   
    def register_referral(referral_id, device_id)
      user = self.where(share_token: referral_id).first
      raise "no user found for given share token" unless user.present?
      share = Share.where(device_id: device_id).first
      if(share.blank?)
        Share.where(user_id: user.id, device_id: device_id).first_or_create!
        statistic = user.statistic
        count = AppSetting.friend_referral_points
        statistic.f_r_score = (statistic.f_r_score += count)
        statistic.save
      end
    end

    def get_users(ids_arr)
      ids_arr ||= []
      users = Array.new
      ids_arr.each do |id|
        u = User.where(_id: id).first
        users << {id: u.id.to_s, name: u.name, image_url: u.image_url}
      end
      users
    end

    def save_inactive_user(mobile_number, country_code)
      user =  User.where(mobile_number: mobile_number).first_or_initialize
      user.country_code = country_code
      user.skip_update_validation = true
      user.save
      user
    end  

    def send_welcome_message(id)
      num = Rails.application.secrets.w_mobile_number
      num = User.mobile_number_format(num) 
      sender = User.where(mobile_number: num[:mobile_number]).first
      w_message = AppSetting.welcome_chat_message
      chat_url = Rails.application.secrets.chat_url
      str = "?sender_id=#{sender.id.to_s}&receiver_id=#{id}&message=#{w_message}&sent_at=#{Time.now.to_s}"
      token = 'Token token='+"\""+sender.auth_token+"\""+","+' device_id='+"\""+sender.encrypt_device_id+"\""
      Unirest.post"#{chat_url}/api/v1/chats/send/#{str}", headers: {"Authorization" => token}
    rescue => e
      false
    end

    def set_mobile_number(user, num)
      num = self.mobile_number_format(num)
      code = num[:country_code]
      mobile = num[:mobile_number]
      if(code.blank?)
        code = user.country_code
      end
      return {mobile_number: mobile, country_code: code}
    end

    def send_chat_message(sender, receiver, msg)
      chat_url = Rails.application.secrets.chat_url
      str = "?sender_id=#{sender.id.to_s}&receiver_id=#{receiver.id.to_s}&message=#{msg}&sent_at=#{Time.now.to_s}"
      token = 'Token token='+"\""+sender.auth_token+"\""+","+' device_id='+"\""+sender.encrypt_device_id+"\""
      Unirest.post"#{chat_url}/api/v1/chats/send/#{str}", headers: {"Authorization" => token}
    end

    def get_users_and_referral_count(users)
      users_obj = Array.new
      users.each do |u|
        id = u["_id"]["user_id"]
        user = User.where(_id: id).first
        next if user.blank?
        count = u["count"]
        users_obj << {name: user.name, id: user.id.to_s, image_url: user.image_url, referral_count: count }
      end
      users_obj
    end
   
    def save_contact_dump(c_dump_id)
      c_dump = ContactDump.where(_id: c_dump_id, status: ContactDump::CONTACT_DUMP_CONS[:FRESH]).first
      return false if c_dump.blank?
      user = User.where(_id: c_dump.user_id).first
      user.save_contacts_with_name(c_dump.contacts)
      c_dump.status = ContactDump::CONTACT_DUMP_CONS[:PROCESSED]
      c_dump.save
    rescue => e
      c_dump.status = ContactDump::CONTACT_DUMP_CONS[:ERROR]
      c_dump.error_msg = e.message
      c_dump.save
    end
  
  end

  ## private methods
  private
    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(auth_token: token).first
      end
    end
end
