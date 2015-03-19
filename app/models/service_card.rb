class ServiceCard
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include ServiceCardSearch
  include GroupAttr
  include Geo

  field :user_id,     type: BSON::ObjectId
  field :listing_id,  type: BSON::ObjectId
  field :tag_id,      type: BSON::ObjectId
  field :title,       type: String
  field :description, type: String
  field :keywords,    type: Array
  field :price,       type: Integer
  field :currency,    type: String
  field :status,      type: Integer, default: 0
  field :latitude,    type: String
  field :longitude,   type: String
  field :city,        type: String
  field :state,       type: String
  field :country,     type: String
  field :address,     type: String
  field :zipcode,     type: String
  field :location,    type: Array
  field :card_score,  type: Integer, default: 0
  ##################### CONS ################################
  SERVICE_CARD = {OFF: 0,  ON: 1, HIDDEN: 2}
  ##################### RELATIONS ###########################
  embeds_one :service_card_image
  ######### carrier Wave ####################################
  mount_uploader :image, CardUploader
  #########  validations ###############################
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
end
