class Contact
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :person_id, type: BSON::ObjectId
  
  ################# validations #########################
  validates :person_id, presence: true, uniqueness: true

end
