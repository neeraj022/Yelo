class ChatBlock
  include Mongoid::Document

  field :status,        type: Integer, default: 1
  field :request_time,  type: DateTime 
  #################### constants ##################
  CONS = {ALLOW: 1, REJECT:2,  BLOCK: 3}
  #################### relations ##################
  embedded_in :chat_log  
  #################### instance methods ###########

  def set_status(type)
  	case type
    when "reject"
      self.status = ChatBlock::CONS[:REJECT]
      self.request_time = Time.now
    when "block"
      self.status = ChatBlock::CONS[:BLOCK]
    when "allow"
      self.status = ChatBlock::CONS[:ALLOW]
    end
    self.save
  end

end
