class Group
  include Mongoid::Document
  
  field :name, type: String 

  has_many :tags

  validates :name, presence: true
end
