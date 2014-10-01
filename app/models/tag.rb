class Tag
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :name, type: String
  field :group_id, type: String
  field :granularity, type: Integer, default: 1
  
  ## relations
  belongs_to :group
  
  ## validators
  validates :name, presence: true

  G_CODE = {LOCAL: 1, CITY: 2}

  ## class methods #############################
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
 
  end
end
