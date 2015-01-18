class Listing
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Geo
  include ListingSearch
    
  field :user_id,         type: BSON::ObjectId
  field :status,          type: Boolean, default: true
  field :title,           type: String
  field :description,     type: String
  field :location,        type: Array
  field :latitude,        type: String
  field :longitude,       type: String
  field :city,            type: String
  field :state,           type: String
  field :country,         type: String
  field :address,         type: String
  field :zipcode,         type: String
  field :tag_id,          type: BSON::ObjectId
  field :referred_count,  type: Integer
  #################### index ###########################
  index({ location: "2d" }, { min: -200, max: 200 })
  ################### relations #########################
  belongs_to  :user, index: true, touch: true
  embeds_many :listing_keywords
  embeds_many :listing_links
  ######################## filters ######################
  validates :user_id, :tag_id, presence: true
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  ########################  instance methods #############

  def save_keywords(words)
    self.listing_keywords.destroy_all
    words.each do |w|
      next if w.blank?
      w = Keyword.format_word(w)
      keyword = Keyword.where(tag_id: self.tag_id, name: w).first_or_create
      next unless keyword.persisted?
      self.listing_keywords.create(name: w, keyword_id: keyword.id, word_id: keyword.word_id)
    end
  end

  def save_links(links)
    self.listing_links.destroy_all
    links.each do |l|
      l = JSON.parse(l)
      next if (l["name"].blank? || l["url"].blank?)
      self.listing_links.create(name: l["name"], url: l["url"])
    end
  end

  def tag_name
    Tag.where(_id: tag_id).first.name
  end

end
