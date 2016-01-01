class ServiceCard
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include ServiceCardSearch
  include GroupAttr
  include Geo

  field :user_id,       type: BSON::ObjectId
  field :listing_id,    type: BSON::ObjectId
  field :tag_id,        type: BSON::ObjectId
  field :title,         type: String
  field :description,   type: String
  field :keywords,      type: Array
  field :price,         type: Integer
  field :currency,      type: String
  field :status,        type: Integer, default: 0
  field :latitude,      type: String
  field :longitude,     type: String
  field :city,          type: String
  field :state,         type: String
  field :country,       type: String
  field :address,       type: String
  field :zipcode,       type: String
  field :location,      type: Array
  field :card_score,    type: Integer, default: 0
  field :duration,      type: Integer, default: 0
  field :duration_type, type: Integer, default: 1
  field :note,          type: String
  field :message,       type: String
  field :image_secure_token, type: String
  field :views,         type: Integer, default: 0
  field :books,         type: Integer, default: 0
  ##################### attribute accessor ##################
  attr_accessor :duration_unit
  ##################### CONS ################################
  SERVICE_CARD  = {OFF: 0,  ON: 1, HIDDEN: 2, REJECT: 4}
  DURATION_TYPE = {DAY: 1, WEEK: 2, MONTH: 3, HOUR: 4}
  #################### FILTERS ##############################
  before_save :set_user_attr, :set_duration_type
  ##################### RELATIONS ###########################
  # embeds_one :service_card_image
  belongs_to :user
  belongs_to :listing
  belongs_to :tag
  has_many :ratings
  has_many :service_sms_logs
  has_many :service_card_books
  has_many :service_card_views
  #################### carrier Wave ####################################
  mount_uploader :image, CardUploader
  #################### validations ###############################
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :title, :description, :price, :user_id, :listing_id, presence: true
  #########  instance methods ###############################
  def image_url
    if !Rails.application.secrets.cloud_storage.present? || self.image.url.include?("fallback")
      Rails.application.secrets.app_url+self.image.url
    else
      self.image.url
    end
  end

  def set_duration_type
    if(self.duration_unit.present?)
      unit = case duration_unit
              when /^days?$/
                ServiceCard::DURATION_TYPE[:DAY]
              when /^weeks?$/
                ServiceCard::DURATION_TYPE[:WEEK]
              when /^months?$/
                ServiceCard::DURATION_TYPE[:MONTH]
              when /^hours?$/
                ServiceCard::DURATION_TYPE[:HOUR]
            end
      self.duration_type = unit
    end
  end

  def duration_time
    unit = case duration_type
         when 1
           "day"
         when 2
           "week"
         when 3
           "month"
         when 4
           "hour"
       end
    ActionController::Base.helpers.pluralize(self.duration, unit)
  end

  def status_in_words
     str = case status
     when ServiceCard::SERVICE_CARD[:ON]
       "ON"
     when ServiceCard::SERVICE_CARD[:OFF]
       "OFF"
     when ServiceCard::SERVICE_CARD[:HIDDEN]
       "HIDDEN"
     when ServiceCard::SERVICE_CARD[:REJECT]
       "REJECTED"
     end
  end

  def set_user_attr
    user = self.user
    user.is_service = true
    user.save
  end

  def views
    self.service_card_views.count
  end

  def owner
    user = self.user
    {id: user.id.to_s, name: user.name, image_url: user.image_url, mobile_number: user.full_mobile_number,
      doc_verified: user.doc_verified}
  end

  def avg_rating
    ratings = self.ratings
    count = ratings.count
    return 0 if (count == 0)
    stars = ratings.sum(:stars)
    avg = (stars/count)
  end
end
