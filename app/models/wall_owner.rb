class WallOwner
  include Mongoid::Document
   
  field :user_id,    type: BSON::ObjectId
  field :name,       type: String
  field :image_url,  type: String 

end
