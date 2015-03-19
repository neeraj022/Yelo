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
  field :location,    type: Array
  field :card_score,  type: Integer, default: 0
  

  ##################### CONS ################################
  SERVICE_CARD = {OFF: 0,  ON: 1, HIDDEN: 2}
  
  embeds_many :service_card_images
end
