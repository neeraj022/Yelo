class ServiceCardSerializer < CustomSerializer
  attributes :id, :title, :description, :price, :currency
  has_many :service_card_images
end
