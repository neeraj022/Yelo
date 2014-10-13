class Setting
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :ns_code, type: Integer, default: 1

  NS_CODE = {NOTIFY_SUMMARY: 1 ,NOTIFY_ALL: 2, NOTIFY_MUTE: 3}
  
  ################# relations ############################
  embedded_in :user
end
