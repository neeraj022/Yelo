class ServiceSmsLog
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :user_id,            type: BSON::ObjectId
  field :last_sms_sent,      type: DateTime, default: Time.now
  field :service_card_id,    type: DateTime, default: Time.now
  
  def can_send_sms?
  	diff_time = Code.time_diff_in_hours(Time.now, self.last_sms_sent)
  	if diff_time >= AppSetting.service_sms_interval
  	  true
  	else
  	  false
  	end
  end

  def send_sms(msg)
    if(can_send_sms?)
      # msg = URI.encode(msg)
      res = Code.send_sms(self.full_mobile_number, msg)
      Rails.logger.info res
      self.last_sms_sent = Time.now
      self.save
    end
  end

  def full_mobile_number
    self.country_code.to_s + self.mobile_number.to_s
  end
end
