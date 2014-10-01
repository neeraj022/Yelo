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

  ## index
  index({ location: "2d" }, { min: -200, max: 200 })
  
  ## relations
  belongs_to  :user
  embeds_many :listing_tags
  
  ## filters
  
  validate :user_id, :city, :latitude, :longitude, presence: true
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  def create_with_tags(tag_ids)
    self.listing_tags.destroy_all if self.persisted?
    tag_ids.each do |id|
      tag = Tag.where(_id: id).first
      next unless tag.present?
      self.listing_tags.create!(tag_id: tag.id, tag_name: tag.name)
    end
    self.save
  end

end
