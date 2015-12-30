class BusinessImage
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  ######## relations #################
  belongs_to	:service_card
  #validations
  # validates 	:service_card, presence: true
  # Photo uploader using carrierwave
  mount_uploader :avatars, BusinessUploader

end