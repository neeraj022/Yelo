class Tag
  include Mongoid::Document

  field :name, type: String
  field :group_id, type: String
  
  ## relations
  belongs_to :group
  
  ## validators
  validates :name, presence: true
end
