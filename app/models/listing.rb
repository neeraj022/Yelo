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
  belongs_to :tag
  ####################  filters          #######################
  after_initialize :init
  ######################## validations #######################
  validates :user_id, :tag_id, presence: true
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates_uniqueness_of :tag_id, :scope => :_id
  ########################  instance methods #################

   def init
    
   end

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
      # l = JSON.parse(l)
      next if (l["url"].blank?)
      self.listing_links.create(url: l["url"])
    end
  end

  def tag_name
    @tag_name ||= Tag.where(_id: tag_id).first.name
  end

  def group_id
    @group_id ||= Group.find(self.tag.group_id).id.to_s
  end

  def group_name
    @group_name ||= Group.find(group_id).name
  end

  def group_color
    @group_color ||= Group.find(group_id).color
  end

  def keyword_ids
    @keyword_ids ||= self.listing_keywords.map{|k| k.keyword_id.to_s}
  end

  def keyword_names
    @keyword_names ||= Keyword.where(:_id.in => keyword_ids).map{|k| k.name}
  end

  def referral_count
    user = self.user
    count = user.user_tags.where(tag_id: self.id).count
    count
  end

end
