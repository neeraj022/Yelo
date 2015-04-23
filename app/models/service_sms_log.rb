class ServiceSmsLog
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :user_id,            type: BSON::ObjectId
  field :last_sms_sent,      type: DateTime, default: 2.hours.ago
  field :service_card_id,    type: BSON::ObjectId

  belongs_to :service_card
  
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
      res = Code.send_sms(full_mobile_number, msg)
      Rails.logger.info res
      self.last_sms_sent = Time.now
      self.save
    end
  end

  def full_mobile_number
    self.service_card.user.full_mobile_number
  end
end
