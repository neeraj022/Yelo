class ChatItem
  include Mongoid::Document

  field :chat_id, type: BSON::ObjectId
  #################### relations ############### 
  embedded_in :chatted_user
end
