class Tag
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :name,         type: String
  field :color,        type: String
  field :group_id,     type: String
  field :granularity,  type: Integer, default: 1
  field :score,        type: Integer, default: 0
  field :status,       type: Boolean, default: false
  ################# relations ################
  belongs_to :group
  has_many :walls
  has_many :keywords
  has_many :listings
  has_many :service_cards
  ################## filters #################
  after_save :update_embed_docs
  ############## validators  #################
  validates :name, presence: true, uniqueness: true
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

    def get_tag_from_group(t_obj)
      return {} if t_obj.blank?
      tags = Array.new
      t_obj.each do |t|
        tg = Tag.where(_id: t["_id"]["tag_id"]).first
        tags << {name: tg.name, id: tg.id.to_s, count: t["tag_count"]  }
      end
      tags
    end

    def get_user_tag_recommends(t_obj, user_id)
      return {} if t_obj.blank?
      tag_hash = Hash.new
      t_obj.each do |t|
        t["_id"]["user_ids"].reject! {|u| u != user_id}
        tg = Tag.where(_id: t["_id"]["tag_id"]).first
        tg_obj = tag_hash[tg.name.to_sym] ||= Array.new
        tg_obj << {name: tg.name, id: tg.id.to_s, count:  t["_id"]["user_ids"].count}
      end
     tags = Tag.formatted_user_tag_recommends(tag_hash)
    end
    
    def formatted_user_tag_recommends(tag_hash)
      tags = Array.new
      tag_hash.each_pair do |k, v|
        count = 0
        name = v[0][:name]
        id = v[0][:id]
        v.each do |t|
          count += t[:count] 
        end
       tags << {name: name, id: id, count: count }
      end
      tags
    end
  end
end
