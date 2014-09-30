class Code
  class << self
    def [](k)
  	  code = {
         :status_success => "success",
         :status_error => "error"
        }
      if code[k.to_sym].present?
        return code[k.to_sym]
      else
        raise "Code not found"
      end
    end
   end
end