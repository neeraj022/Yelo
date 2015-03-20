class ServiceCardSerializer < CustomSerializer
  attributes :id, :title, :description, :price, :currency, :image_url, :owner, :created_at,
  :updated_at
end
