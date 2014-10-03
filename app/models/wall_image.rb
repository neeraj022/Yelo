class WallImage
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  mount_uploader :image, ImageUploader

end
