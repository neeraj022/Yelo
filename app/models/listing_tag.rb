class ListingTag
  include Mongoid::Document

  field :tag_id,     type: BSON::ObjectId
  field :tag_name,   type: String
  field :rating_id,  type: BSON::ObjectId
  field :rating_avg, type: Integer, default: 0

  validates :tag_id, :tag_name, presence: true
  validates :tag_id, uniqueness: true
  
  embedded_in :listing

  after_create  :update_tag_ids
  after_destroy :update_tag_ids

  def update_tag_ids
    wall = self.wall
    wall.tag_ids = []
    wall.tag_ids = wall.listing_tags.map{|l| l.tag_id.to_s}
  end

end
