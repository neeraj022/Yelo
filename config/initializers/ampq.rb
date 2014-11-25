# require 'amqp'

module ThinEM
  def self.start
    EventMachine.next_tick do
      connection = AMQP.connect(:host => Rails.application.secrets.rabbitmq_url, :user=>Rails.application.secrets.rabbitmq_user, :pass => Rails.application.secrets.rabbitmq_password, :vhost => "/")
      AMQP.channel ||= AMQP::Channel.new(connection)
      channel = AMQP.channel
     
      #-------------------
      # s_exchange = channel.fanout("53fd874c62617276e32c0000exchange")
      # u_exchange = channel.fanout("543b972d79656c39970c0000exchange")
      # u_queue = channel.queue("543b972d79656c39970c0000queue", :auto_delete => true).bind(u_exchange)
      # s_queue = channel.queue("53fd874c62617276e32c0000queue", :auto_delete => true).bind(s_exchange) 
      # s_exchange.publish("publishing test")

      # u_queue.subscribe do |payload|
      #   puts "Received a message: #{payload}. Disconnecting..."
      #   # connection.close { EventMachine.stop }
      # end
      # s_queue.subscribe do |payload|
      #   puts "Received a message: #{payload}. Disconnecting..."
      #   # connection.close { EventMachine.stop }
      # end
      # connection.on_tcp_connection_loss do |connection, settings|
      #     # reconnect in 10 seconds, without enforcement
      #     connection.reconnect(false, 10)
      # end
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

      #-------------------
       puts "thin em started"
       puts "#{Rails.application.secrets.rabbitmq_url}"
    end
  end
end

module PassengerEM
  def self.start
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      # for passenger, we need to avoid orphaned threads
        if forked && EM.reactor_running?
          EM.stop
        end
        Thread.new {
          EM.run do
            AMQP.channel ||= AMQP::Channel.new(AMQP.connect(:host => Rails.application.secrets.rabbitmq_url, :user=>Rails.application.secrets.rabbitmq_user, :pass => Rails.application.secrets.rabbitmq_password, :vhost => "/"))
          end
          }
        die_gracefully_on_signal
     end
  end
  

  def self.die_gracefully_on_signal
    Signal.trap("INT") { EM.stop }
    Signal.trap("TERM") { EM.stop }
  end
end

# if defined?(PhusionPassenger)
#   PassengerEM.start
# end

if defined?(Thin)
  ThinEM.start
end


   