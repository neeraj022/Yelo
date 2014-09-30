class Group
  include Mongoid::Document
  
  field :name, type: String 
  
  ## relations
  has_many :tags
  
  ## validators
  validates :name, presence: true
end
