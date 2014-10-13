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
       if(Rails.env == "production")
          "Error, something went wrong"
       else 
          e.message
       end
     end
   end

  def self.serialized_json(obj, class_name = nil)
    if obj.kind_of?(Array)
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

  def self.send_sms(num, msg)
    sms_api_key = Rails.application.secrets.sms_api_key
    request_url = "http://global.sinfini.com/api/v1/?api_key=#{sms_api_key}&method=sms&sender=yelo&to=#{num}&message=#{msg}"
    response = open(request_url).read
    response
  end

  def time_diff_in_hours(time1, time2)
    ((time1 - time2) / 3600).round
  end

end