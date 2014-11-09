class ContactWallWorker
  include Sidekiq::Worker
  sidekiq_options queue: "contact_wall", retry: false

  def perform(user_id, wall_id)
    Notification.save_contact_wall(user_id, wall_id)
  end

end