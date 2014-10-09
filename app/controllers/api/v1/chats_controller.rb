class Api::V1::ChatsController < Api::V1::BaseController
  before_action :authenticate_user!
  
  # POST /chat
  def send_chat
    if params[:sender_id]  == current_user.id.to_s
      ampq(params)
      render json: {status: "success"}
    else
      render json: {status: "error", error_message: "sender is not you"}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  def ampq(params)
    EM.next_tick {
      connection = AMQP.connect(:host => Rails.application.secrets.rabbitmq_url, :user=>Rails.application.secrets.rabbitmq_user, :pass => Rails.application.secrets.rabbitmq_password, :vhost => "/")
      AMQP.channel ||= AMQP::Channel.new(connection)
      channel  = AMQP.channel
      channel.auto_recovery = true
      begin
        obj = Chat.set_chat(params) 
      rescue => e
        obj[:status] = false
        e = "" if Rails.env == "production"
        obj[:message] = "something went wrong #{e}"
      end
      obj[:server_sent_at] = Time.now
      if(obj[:status])
        receiver_exchange = channel.fanout(obj[:receiver_id]+"exchange")
        receiver_exchange.publish(obj.to_json)
      end
      sender_exchange = channel.fanout(obj[:sender_id]+"exchange") 
      sender_exchange.publish(obj.to_json)
      connection.on_tcp_connection_loss do |connection, settings|
        # reconnect in 10 seconds, without enforcement
        connection.reconnect(false, 10)
      end
      connection.on_error do |conn, connection_close|
        puts <<-ERR
        Handling a connection-level exception.
        AMQP class id : #{connection_close.class_id},
        AMQP method id: #{connection_close.method_id},
        Status code   : #{connection_close.reply_code}
        Error message : #{connection_close.reply_text}
        ERR
       conn.periodically_reconnect(30)
      end
      EventMachine::error_handler { |e| puts "error! in eventmachine #{e}" }
    }
  end

  # # POST /chats/seen
  def set_seen
  	time =  Time.parse(params[:created_at])
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

end
