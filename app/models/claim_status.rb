class ClaimStatus
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  field :amount, type: Integer
  field :status, type: String

  belongs_to :user
end
