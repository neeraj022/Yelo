class Tag
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :name, type: String
  field :group_id, type: String
  field :granularity, type: Integer, default: 1
  field :score, type: Integer, default: 0
  ################# relations ################
  belongs_to :group
  has_many :walls
  ################## filters #################
  after_save :update_embed_docs
  ############## validators  #################
  validates :name, presence: true
  ############## constants ###################
  G_CODE = {LOCAL: 1, CITY: 2}
  ############## instance methods ############
  def save_score
    self.score = self.score += 1
    self.save
  end

  def update_embed_docs
    if(name_changed?)
      update_wall_tag_name
      update_listing_tag_name
      update_rating_tag_name
    end
  end

  def update_wall_tag_name
    walls = self.walls
    walls.each do |w|
      w.tag_name = self.name
      w.save
    end
  end

  def update_rating_tag_name
    ratings = Rating.where("rating_tags.tag_id" => self.id)
    ratings.each do |r|
      r = r.rating_tags.where(tag_id: self.id).first
      r.tag_name  = self.name
      r.save
    end
  end

  def update_listing_tag_name
    listings = Listing.where("listing_tags.tag_id" => self.id)
    listings.each do |l|
      tg = l.listing_tags.where(tag_id: self.id).first
      tg.tag_name = self.name
      tg.save
    end
  end 

  ############## class methods #############
  class << self
    
    def verify_ids(tag_ids)
      ids = Array.new
      tag_ids.each do |id|
         tag = Tag.where(_id: id).first
         next unless tag.present?
         ids << id
	     end
      ids
    end

    def auto_suggestions(name)
      tags = Tag.where(name: /^#{name}/i).limit(10)
      tags_array = tags.map{|t| {id: t.id.to_s, name: t.name}}
      tags_array
    end
 
  end
end
