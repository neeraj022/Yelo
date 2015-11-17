
class PushRecordWorker
  include Sidekiq::Worker
  sidekiq_options queue: "notification", retry: false

  def perform(n_id)
    notification = PushRecord.where(_id: n_id).first
    notification.send_notification if notification.present?
  end

end
