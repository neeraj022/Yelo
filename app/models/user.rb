class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ## Database authenticatable
  field :mobile_number,        type: String, default: ""
  field :name,                 type: String
  field :description,          type: String
  field :platform,             type: String
  field :encypt_device_id,     type: String
  field :push_id,              type: String
  field :country_code,         type: String
  field :email,                type: String, default: ""
  field :encrypted_password,   type: String, default: ""
  field :avatar_off,           type: String, default: false
  field :interest_ids,         type: Array 
  field :status,               type: Boolean, default: true
  field :abuse_count,          type: Boolean, default: 0     
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

  has_many     :listings
  embeds_one   :setting
  embeds_one   :statistic

  def s_id
    self.id.to_s
  end

  def tags
    tags = Array.new
    self.listings.each do |l|
      l.listing_tags.each{|t| tags << {id: t.tag_id ,name: t.tag_name}}
    end
    tags
  end

  validates :mobile_number, presence: true,
                      numericality: true,
                      uniqueness: true,
                      length: { minimum: 10, maximum: 15 }
  validates :email, uniqueness: true, allow_blank: true, allow_nil: true
  validates :push_token, :name, :platform, :encypt_device_id, :description,
             presence: true, on: :update
  validates :description, presence: true, on: :update

end
