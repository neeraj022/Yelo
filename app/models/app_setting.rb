class AppSetting
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :posts_per_day,           type: Integer, default: 3
  field :post_time_interval,      type: Integer, default: 10 # in minutes
  field :summary_notify_interval, type: Integer, default: 24    
  field :default_notify_code,     type: Integer, default: 1
  field :wall_notify_radius,      type: Integer, default: 12
  field :chat_reject_interval,    type: Integer, default: 6
  ############### class methods ############################
  class << self
    def wall_post_interval
      if AppSetting.first
        AppSetting.first.post_time_interval * 60
      else
        1 * 60
      end
    end

    def summary_notify_interval
      if AppSetting.first
        AppSetting.summary_notify_interval
      else
        24
      end
    end

    def chat_reject_interval
      if AppSetting.first
        AppSetting.chat_reject_interval
      else
        1
      end
    end

    def wall_notify_radius
      if AppSetting.first
        AppSetting.first.wall_notify_radius 
      else
        12
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
