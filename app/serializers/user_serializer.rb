class UserSerializer < CustomSerializer
  attributes :id, :name, :description, :image_url, :rating_avg, :total_tagged, 
             :total_ratings, :connects_count, :share_token, :platform_version
  has_many :ratings
  has_many :listings
end
