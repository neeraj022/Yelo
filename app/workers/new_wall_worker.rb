
class NewWallWorker
  include Sidekiq::Worker
  sidekiq_options queue: "new_wall", retry: false

  def perform(wall_id)
    Notification.save_wall(wall_id)
  end

end