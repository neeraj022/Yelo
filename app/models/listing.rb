class Listing
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Geo
    
  field :user_id,    type: BSON::ObjectId
  field :status,     type: Boolean, default: true
  field :location,   type: Array
  field :latitude,   type: String
  field :longitude,  type: String
  field :city,       type: String
  field :state,      type: String
  field :country,    type: String
  field :address,    type: String
  field :zipcode,    type: String
  field :tag_ids,    type: Array
  ## index
  index({ location: "2d" }, { min: -200, max: 200 })
  
  ## relations ################
  belongs_to  :user, index: true
  embeds_many :listing_tags
  before_save :insert_tag_ids
  
  ## filters ###################
  validate :user_id, :city, :country, :latitude, :longitude, presence: true
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  def insert_tag_ids
     self.tag_ids = []
     self.tag_ids = self.listing_tags.map{|l| l.tag_id.to_s}
  end

  def create_tags(tag_ids)
    tag_ids.each do |id|
      tag = Tag.where(_id: id).first
      next unless tag.present?
      l_tag = self.listing_tags.create!(tag_id: tag.id, tag_name: tag.name)
      self.save
      tag.save_score
    end
    return {status: true}
  rescue => e 
     e = l_tag.errors.full_messages if l_tag.errors.present?
     return {status: false, error_message: e}
  end

end
