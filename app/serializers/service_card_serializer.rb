class ServiceCardSerializer < CustomSerializer
  attributes :id, :title, :description, :price, :currency, :image_url, :owner, :created_at,
  :updated_at, :group_name, :group_id, :group_color, :tag_name, :tag_id, :avg_rating, :duration_time,
  :note, :status, :message, :books, :views, :email, :mobile_number, :website_url, :latitude, :longitude
  has_many :ratings

  def email
    "#{object.email}".blank? ? "" : "#{object.email}"
  end

  def mobile_number
    "#{object.mobile_number}".blank? ? "" : "#{object.mobile_number}"
  end

  def website_url
    "#{object.website_url}".blank? ? "" : "#{object.website_url}"
  end
end
