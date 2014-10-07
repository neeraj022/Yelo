class WallImage
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  ######## relations #################
  embedded_in :wall

  mount_uploader :image, ImageUploader

  #########  instance methods ################
  def image_url
    if !Rails.application.secrets.cloud_storage.present? || self.image.url.include?("fallback")
      Rails.application.secrets.app_url+self.image.thumb.url
    else
      self.image.thumb.url
    end
  end

end
