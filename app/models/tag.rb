class Tag
  include Mongoid::Document

  field :name, type: String
  field :group_id, type: String
  field :granularity, type: Integer, default: 1
  
  ## relations
  belongs_to :group
  
  ## validators
  validates :name, presence: true

  G_CODE = {LOCAL: 1, CITY: 2}

end
