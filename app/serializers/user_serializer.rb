class UserSerializer < CustomSerializer
  attributes :id, :name, :description, :image_url, :rating_avg, :total_tagged, 
             :total_ratings
  has_many :ratings
end
