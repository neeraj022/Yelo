class ChattedUser
  include Mongoid::Document

  field :user_id, type: BSON::ObjectId
  #################### relations ###############
  embedded_in :chat_log
  embeds_many :chat_items

end
