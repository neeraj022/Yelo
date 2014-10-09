class ChatBlock
  include Mongoid::Document

  field :status,        type: Integer, default: 1
  field :request_time,  type: DateTime 
  #################### constants ################
  CONS = {ALLOW: 1, REJECT:2,  BLOCK: 3}
  #################### relations ###############
  embedded_in :chat_log  
end
