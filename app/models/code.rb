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

  def self.wall_post_interval
    if AppSetting.first
      AppSetting.first.post_time_interval * 60
    else
      1 * 60
    end
  end
end