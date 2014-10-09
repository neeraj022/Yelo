class ChatItem
  include Mongoid::Document

  field :chat_id, type: BSON::ObjectId
  #################### relations ############### 
  embedded_in :chat_log
end
