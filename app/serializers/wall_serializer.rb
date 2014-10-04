class WallSerializer < CustomSerializer
  attributes :id, :message
  has_many :wall_images
  has_one :wall_owner

end
