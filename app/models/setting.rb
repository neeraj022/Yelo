class Setting
  include Mongoid::Document
  
  field :ns_code, type: Integer, default: Setting.NS_CODE[:NOTIFY_SUMMARY]

  NS_CODE = {NOTIFY_SUMMARY: 1 ,NOTIFY_ALL: 2, NOTIFY_MUTE: 3}

  embedded_in :user
end
