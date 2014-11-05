class FriendWallWorker
  include Sidekiq::Worker
  sidekiq_options queue: "friendwall", retry: false

  def perform(user_id, wall_id)
    Notification.friend_wall_notify(user_id, wall_id)
  end

end