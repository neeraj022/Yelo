class WallImage
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  ######## relations #################
  embedded_in :wall

  mount_uploader :image, ImageUploader

end
