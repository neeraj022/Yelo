class Tag
  include Mongoid::Document

  field :name, type: String
  field :group_id, type: String

  belongs_to :group

  validates :name, presence: true
end
