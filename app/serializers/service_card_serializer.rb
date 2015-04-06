class ServiceCardSerializer < CustomSerializer
  attributes :id, :title, :description, :price, :currency, :image_url, :owner, :created_at,
  :updated_at, :group_name, :group_id, :group_color, :tag_name, :tag_id, :avg_rating, :duration,
  :duration_unit
  has_many :ratings
end
