# require 'amqp'

module ThinEM
  def self.start
    EventMachine.next_tick do
      AMQP.channel ||= AMQP::Channel.new(AMQP.connect(:host => Rails.application.secrets.rabbitmq_url, :user=>Rails.application.secrets.rabbitmq_user, :pass => Rails.application.secrets.rabbitmq_password, :vhost => "/"))
      channel = AMQP.channel
     
      #-------------------
      s_exchange = channel.fanout("53fce1cd6261727446000000exchange")
      u_exchange = channel.fanout("5421a4cf6261721838af0300exchange")
      u_queue = channel.queue("5421a4cf6261721838af0300queue", :auto_delete => true).bind(u_exchange)
      s_queue = channel.queue("53fce1cd6261727446000000queue", :auto_delete => true).bind(s_exchange) 
      s_exchange.publish("publishing test")

      u_queue.subscribe do |payload|
        puts "Received a message: #{payload}. Disconnecting..."
        # connection.close { EventMachine.stop }
      end
      s_queue.subscribe do |payload|
        puts "Received a message: #{payload}. Disconnecting..."
        # connection.close { EventMachine.stop }
      end
      #-------------------
       puts "thin em started"
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


   