class CommentNotifyWorker
  include Sidekiq::Worker
  sidekiq_options queue: "comment", retry: false

  def perform(wall_id, comment_id, user_id)
    Notification.send_comment_notifications(wall_id, comment_id, user_id)
  end

end