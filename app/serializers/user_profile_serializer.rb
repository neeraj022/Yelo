class UserProfileSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :image_url, :rating_avg, :total_tagged, 
             :total_ratings, :connects_count, :share_token, :platform_version, :profile_image
end
