class Tag
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :name, type: String
  field :group_id, type: String
  field :granularity, type: Integer, default: 1
  field :score, type: Integer, default: 0
  ## relations
  belongs_to :group
  
  ############## validators  ##############
  validates :name, presence: true

  G_CODE = {LOCAL: 1, CITY: 2}

  def save_score
    self.score = self.score += 1
    self.save
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
