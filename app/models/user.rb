class User
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Geo  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  attr_accessor :serial_present
  
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
  field :sms_verify,           type: Boolean, default: false
  field :auth_token,           type: String
  field :share_token,          type: String
  field :ext_image_url,        type: String
  field :location,             type: Array
  field :city,                 type: String
  field :state,                type: String
  field :country,              type: String
  field :is_present,           type: Boolean, default: false
  field :latitude,   type: String
  field :longitude,  type: String
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
  ## index
  index({ location: "2d" }, { min: -200, max: 200 })
  index "mobile_number" => 1
  index "auth_token" => 1
  ## carrier wave
  mount_uploader :image, ImageUploader

  ## relations
  has_many     :listings
  embeds_one   :setting
  embeds_one   :statistic

  ## filters
  before_save :ensure_authentication_token, :mobile_verification_serial
                          
  before_create :ensure_share_token
  before_validation :ensure_password

  ## validators
  validates :mobile_number, presence: true,
                      numericality: true,
                      uniqueness: true,
                      length: { is: 10 }
  validates :email, uniqueness: true, allow_blank: true, allow_nil: true
  validates :push_id, :platform, :encrypt_device_id,
             presence: true, on: :update
  validates :description, :name, presence: true, on: :update, :if => :validate_profile?
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }, 
            on: :update,  :if => :validate_profile?
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, on: :update,
            on: :update,  :if => :validate_profile?
  validates :city, :country, presence: true, on: :update, :if => :validate_profile?

  def tags
    tags = Array.new
    self.listings.each do |l|
      l.listing_tags.each{|t| tags << {id: t.tag_id ,name: t.tag_name}}
    end
    tags
  end

  def validate_profile?
    if self.serial_present
      false
    else
      true
    end  
  end

  def online?
    updated_at > 10.minutes.ago
  end

  ## Model work methods #####################################
  
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
      Rails.application.secrets.app_url+self.image.thumb.url
    else
      self.image.thumb.url
    end
  end

  ## before actions ######################################
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
    return if self.password.present?
    self.password = Devise.friendly_token
  end
 
  ## class methods ###########################
  class << self
    def mobile_number_format(num)
      mobile_number = num.slice!(-(10-num.length), 10)
      {mobile_number: mobile_number, country_code: num}
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
