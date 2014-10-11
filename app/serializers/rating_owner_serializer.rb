class RatingOwnerSerializer < ActiveModel::Serializer
  attributes :user_id, :name, :image_url
  
end
