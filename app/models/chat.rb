class Chat
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :receiver_id,   type: BSON::ObjectId
  field :sender_id,     type: BSON::ObjectId
  field :reply_id,      type: BSON::ObjectId
  field :message,       type: String
  field :is_seen,       type: Boolean, default: false
  field :seen_at,       type: DateTime
  ############## instance methids ###################
  def chat_format
    {message: message, sender_id: sender_id.to_s, receiver_id: receiver_id.to_s, created_at: created_at, 
     reply_id: reply_id, id: id.to_s}
  end
  ############## class methods ######################
  class << self
    
    def create_chat(params)
      chat = Chat.create(sender_id: params[:sender_id], receiver_id: params[:receiver_id],
       message: params[:message], reply_id: params[:reply_id], is_seen: false)
      if(params[:wall_id].present?)
         Wall.save_wall_chat_user(params[:wall_id], params[:sender_id])
      end
      chat
    end
    
    def set_chat(params)
      receiver =  User.where(_id: params[:receiver_id]).first
      sender =  User.where(_id: params[:sender_id]).first
      if receiver.present? && sender.present?
        chat_state = self.block_details(receiver.id, params[:sender_id])
      else
       chat_state =  {can_send: false, message: "there is no receiver to send"}
      end
      if(chat_state[:can_send])
        chat = Chat.create_chat(params)
        params[:status] = true
        params[:reply_id] = chat.id.to_s
        params[:created_at] = chat.created_at
        ChatLog.save_chats(chat_state[:r_log], chat.id)
        ChatLog.save_chats(chat_state[:s_log], chat.id)
      else
       params[:message] = chat_state[:message]
       params[:status] = false
      end 
      return params     
    end

    def block_details(r_id, s_id)
      r_log = ChatLog.where(user_id: r_id, chatter_id: s_id).first_or_create
      s_log = ChatLog.where(user_id: s_id, chatter_id: r_id).first_or_create
      r_block  = r_log.chat_block
      s_block  = s_log.chat_block
      if((s_block == ChatBlock::CONS[:BLOCK]) || (s_block == ChatBlock::CONS[:REJECT]) )
        s_block.status = ChatBlock::CONS[:ALLOW]
        s_block.save
      end
      result = block_state(r_block)
      result[:r_log] = r_log
      result[:s_log] = s_log
      return result
    end

    def block_state(r_block)
      result = Hash.new
      if(r_block.present?)
         case r_block.status
         when ChatBlock::CONS[:ALLOW]
           result[:can_send] = true
         when ChatBlock::CONS[:BLOCK]
           result[:can_send] = false
           result[:message] = "You cant chat with this user"
         when ChatBlock::CONS[:REJECT]
          result[:can_send] = Chat.reject_status(r_block)
          result[:message] = "you can only chat after #{AppSetting.chat_reject_interval} hours"
         else
           result[:can_send] = true
         end
       else
         result[:can_send] = true
      end
       result
    end

    def reject_status(block_obj)
      request_time = block_obj.request_time
      interval = AppSetting.chat_reject_interval
      diff = ((Time.now - request_time).to_f / 3600).round
      if(interval <= diff)
        true
      else
       false
      end
    end
  end

end
