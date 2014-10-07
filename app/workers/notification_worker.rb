# app/workers/chat_log_worker.rb
class NotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: "notification", retry: false

  def perform(params)
    case params[:type]
  	when "wall_create"
      Notification.save_wall(params[:wall_id]) 
    end
  end

end