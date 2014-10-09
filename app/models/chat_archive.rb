class ChatArchive
  include Mongoid::Document

  field :receiver_id,   type: BSON::ObjectId
  field :sender_id,     type: BSON::ObjectId
  field :reply_id,      type: BSON::ObjectId
  field :message,       type: String
  field :is_seen,       type: Boolean
  field :chat_id,       type: BSON::ObjectId

end
