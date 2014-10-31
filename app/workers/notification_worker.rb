# app/workers/chat_log_worker.rb
class NotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: "notification", retry: false

  def perform(n_id)
    notification = Notification.where(_id: n_id).first
    notification.send_notification if notification.present?
  end

end