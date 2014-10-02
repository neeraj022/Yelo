module Geo
  extend ActiveSupport::Concern

  included do
    before_save :update_geo_location, :downcase_address
  end

  # module ClassMethods
  #   ## class methods
  # end
  def update_geo_location
    if latitude.present? && longitude.present?
      self.location = [longitude.to_f, latitude.to_f]
    end
  end

  def downcase_address
    if country.present? 
      self.country = country.downcase
    end
    if city.present? 
      self.country = country.downcase
    end
  end

end