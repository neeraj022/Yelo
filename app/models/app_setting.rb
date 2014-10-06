class AppSetting
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :posts_per_day,         type: Integer, default: 3
  field :post_time_interval,    type: Integer, default: 10 # in minutes
  field :summary_notification,  type: Integer, default: 1    
  field :default_notify_code,   type: Integer, default: 1

  class << self
    def wall_post_interval
      if AppSetting.first
        AppSetting.first.post_time_interval * 60
      else
        1 * 60
      end
    end

    def default_notify_setting
      if AppSetting.first
        AppSetting.first.default_notify_code
      else
         1
      end
    end
  end
end
