class ChatLog
  include Mongoid::Document

  field :user_id,    type: BSON::ObjectId
  field :chatter_id, type: BSON::ObjectId
  ############### relations ##############
  belongs_to  :user
  embeds_many :chat_items
  embeds_one  :chat_block
  ############## class methods ############
  class << self
    def save_chats(obj, chat_id)
      obj.chat_items.create(chat_id: chat_id)
    end
  end
end
