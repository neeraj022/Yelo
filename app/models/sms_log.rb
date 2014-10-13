class SmsLog
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :mobile_number, type: Integer
  field :country_code,  type: Integer
  field :last_sms_sent, type: DateTime, default: Time.now

  def can_send_sms?
  	diff_time = Code.time_diff_in_hours(Time.now, self.last_sms_sent)
  	if diff_time <= AppSetting.tagged_user_sms_interval
  	  true
  	else
  	  false
  	end
  end

  def send_sms(msg)
    if(can_send_sms?)
      Code.send_sms(self.full_mobile_number, msg)
    end
  end

  def full_mobile_number
    self.country_code.to_s + self.mobile_number.to_s
  end

end
