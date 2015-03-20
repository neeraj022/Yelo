class Api::V1::ChatsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:notify]
  
  # POST /chat
  def send_chat
    if params[:sender_id]  == current_user.id.to_s
      params[:message] = params[:message].to_s.truncate(600)
      ampq(params)
      render json: {status: "success"}
    else
      render json: {status: "error", error_message: "sender not found"}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  def ampq(params)
    channel  = AMQP.channel
    channel.auto_recovery = true
    begin
      obj = Chat.set_chat(params) 
    rescue => e
      obj[:status] = false
      e = "" if Rails.env == "production"
      obj[:message] = "something went wrong #{e}"
    end
    obj[:server_sent_at] = Time.now.to_s
    if(obj[:status])
      channel.queue("#{obj[:receiver_id]}queue", :auto_delete => false, durable: true)
      receiver_exchange = channel.fanout(obj[:receiver_id]+"exchange")
      receiver_exchange.publish(obj.to_json)
      rec = User.where(_id: obj[:receiver_id]).first
      unless rec.online?
        rec.alert_notify
        # GcmChatWorker.perform_in(5.minutes, rec.id.to_s)
          GcmPing.where(user_id: rec.id).first_or_create
      end
    end
    sender_exchange = channel.fanout(obj[:sender_id]+"exchange") 
    sender_exchange.publish(obj.to_json)
  end

  ## POST /chats/seen
  def set_seen
  	time =  Time.parse(params[:created_at]) 
    time += 1.minutes
    Chat.where(:created_at.lte => time, is_seen: false, receiver_id: current_user.id.to_s).update_all(is_seen: true)
    render json: {status: "success"}
  rescue => e
    rescue_message(e)
  end

  # # POST /chats/status
  def set_status
    chat_log =  current_user.chat_logs.where(chatter_id: params[:chatter_id]).first
    block = chat_log.chat_block
    block = chat_log.build_chat_block unless block.present?
    if block.set_status(params[:type].downcase.strip)
      render json: {status: "success"}
    else
      render json: {status: "error", error_message: block.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end
  
  # GET /notify
  def notify
    #Notification.wall_summary_notify
  end

  # GET /users/chats
  def user_chats
    c_obj = Array.new
    chat_logs = current_user.chat_logs
    chat_logs.each do |u|
      ch = Hash.new
      other_user = User.where(_id: u.chatter_id).first
      next unless other_user.present?
      ch[:user] = {name: other_user.name, id: other_user.id.to_s}
      ch[:chats] = u.get_messages
      c_obj << ch
    end
  render json: {chats: c_obj}
  rescue => e
    rescue_message(e)
  end

end




