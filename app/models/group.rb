class Group
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :name,  type: String 
  field :color, type: String
  
  ## relations
  has_many :tags
  
  ## validators
  validates :name, presence: true
end
