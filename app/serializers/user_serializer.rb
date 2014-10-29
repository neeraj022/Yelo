class UserSerializer < CustomSerializer
  attributes :id, :name, :description, :image_url, :rating_avg, :total_tagged, 
             :total_ratings, :connects
  has_many :ratings
  has_many :listings
end
