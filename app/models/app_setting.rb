class AppSetting
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :posts_per_day,            type: Integer, default: 3
  field :post_time_interval,       type: Integer, default: 10 # in minutes
  field :summary_notify_interval,  type: Integer, default: 24    
  field :default_notify_code,      type: Integer, default: 1
  field :wall_notify_radius,       type: Integer, default: 12
  field :chat_reject_interval,     type: Integer, default: 6
  field :server_status,            type: Integer, default: 1
  field :server_message,           type: String
  field :sms_per_day,              type: Integer, default: 5
  field :tagged_user_sms_interval, type: Integer, default: 1
  field :android_app_url,          type: String
  field :ios_app_url,              type: String
  field :windows_app_url,          type: String
  field :max_abuse_count,          type: Integer, default: 10
  ############### class methods ############################
  class << self
    # in minutes
    def wall_post_interval
      setting = AppSetting.first
      if setting
        setting.post_time_interval * 60
      else
        1 * 60
      end
    end
    
    # in hours
    def summary_notify_interval
      setting = AppSetting.first
      if setting
        setting.summary_notify_interval
      else
        24
      end
    end

    def max_abuse_count
      setting = AppSetting.first
      if setting
        setting.max_abuse_count
      else
        10
      end
    end

    def mobile_app_url
     setting = AppSetting.first
     if setting
       ios = setting.ios_app_url
       android = setting.android_app_url
       windows = setting.windows_app_url
     else
      ios = "https://itunes.apple.com/en/app/apple-store/id375380948?mt=8"
      android = "https://play.google.com/store?hl=en"
      windows = ""
     end
     {android: android, ios: ios, windows: windows}
    end

    def chat_reject_interval
      setting = AppSetting.first
      if setting
        setting.chat_reject_interval
      else
        1
      end
    end

    def tagged_user_sms_interval
      setting = AppSetting.first
      if setting
        setting.tagged_user_sms_interval
      else
        1
      end
    end

    def sms_per_day
      setting = AppSetting.first
      if setting
        setting.sms_per_day
      else
        5
      end
    end

    def server_status
      setting = AppSetting.first
      if setting
        {code: setting.server_status, message: setting.server_message}
      else
        {code: 1, message: "ok"}
      end
    end

    def wall_notify_radius
      setting = AppSetting.first
      if setting
        setting.wall_notify_radius 
      else
        12
      end
    end

    def default_notify_setting
      setting = AppSetting.first
      if setting
        setting.default_notify_code
      else
         1
      end
    end
  end
end
