class Code
  class << self
    def [](k)
  	  code = {
         :status_success => "success",
         :status_error => "error",
         :error_code => 400
        }
      if code[k.to_sym].present?
        return code[k.to_sym]
      else
        raise "Code not found"
      end
    end

     def error_message(e)
       if(Rails.env == "production1")
          "Error, something went wrong"
       else 
          e.message
       end
     end
   end

   def self.email_regex
     str = '^(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})$'
     return Regexp.new(str, Regexp::IGNORECASE)
   end

   def self.phone_regex
     #str = "^(?:(?:\+?1\s*(?:[.-]\s*)?)?(?:\(\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s*\)|([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s*(?:[.-]\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s*(?:[.-]\s*)?([0-9]{4})(?:\s*(?:#|x\.?|ext\.?|extension)\s*(\d+))?$"
    str = "^[0-9\+]{7,13}$"
    return Regexp.new(str)
   end

  def self.serialized_json(obj, class_name = nil)
    if obj.kind_of?(Mongoid::Criteria)
      ActiveModel::ArraySerializer.new(obj).as_json
    elsif(class_name)
      class_name.constantize.new(obj, root: false)
    else
      "error"
    end
  end

  def self.utc_time(utc_offset)
    zone_name = ActiveSupport::TimeZone[utc_offset].name
    zone = ActiveSupport::TimeZone[zone_name]
    time_locally = Time.now
    z_time = zone.at(time_locally)
    #z_time.hour
  end

  def self.encrypt_aes(str)
    encrypt_key = Rails.application.secrets.encrypt_key
    Yelo::Aes.encrypt("salt-hs%$#%hjh", "96DDFA2EAD8C06D3AB445E118DC191D7", str, encrypt_key)
  end

  def self.send_sms(num, msg)
    if(num.to_s.match(/^91/))
      self.send_indian_sms(num, msg)
    else
      self.send_twilio_sms(num, msg)
    end
  end

  def self.send_indian_sms(num, msg)
    sms_api_key = Rails.application.secrets.sms_api_key
    sms = Unirest.get "https://control.msg91.com/api/sendhttp.php?authkey=#{sms_api_key}&mobiles=#{num}&message=#{msg}&sender=YELOOO&route=4"
    sms
  end


  def self.send_twilio_sms(num, msg)
    # request_url = "http://global.sinfini.com/api/v1/?api_key=#{sms_api_key}&method=sms&sender=yelo&to=#{num}&message=#{msg}"
    # response = open(request_url).read
    account_sid = Rails.application.secrets.twilio_account_sid
    auth_token = Rails.application.secrets.twilio_auth_token
    client = Twilio::REST::Client.new account_sid, auth_token
    ss = client.account.messages.create(
        :from => '(847) 380-8587',
        :to => "+"+num.to_s,
        :body => msg
     )
    ss
  end

  def self.time_diff_in_hours(time1, time2)
    ((time1 - time2) / 3600).floor
  end

end


