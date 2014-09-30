class AppSetting
  include Mongoid::Document

  field :posts_per_day,         type: Integer, default: 3
  field :post_time_interval,   type: Integer, default: 60 # in minutes
  field :summary_notification, type: Integer, default: 1    
end
