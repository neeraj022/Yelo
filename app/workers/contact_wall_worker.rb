class ContactWallWorker
  include Sidekiq::Worker
  sidekiq_options queue: "contact_wall", retry: false

  def perform(n_id)
    notification = Notification.where(_id: n_id).first
    notification.send_notification if notification.present?
  end

end