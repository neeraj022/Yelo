class CName
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  field :name,      type: String
  field :a_name,    type: Array
  field :user_id,   type: BSON::ObjectId
  
  ##### relations ######################
  embedded_in :person

end
