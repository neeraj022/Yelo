class RatingSerializer < CustomSerializer
  attributes :id,, :comment, :stars
  has_one :rating_owner
  has_many :rating_tags
end
