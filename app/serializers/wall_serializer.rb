class WallSerializer < CustomSerializer
  attributes :id, :message
  has_one :wall_image
  has_one :wall_owner

end
