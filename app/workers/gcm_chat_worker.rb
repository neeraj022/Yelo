class GcmChatWorker
  include Sidekiq::Worker
  sidekiq_options queue: "gcm_chat", retry: false

  def perform(id)
    user = User.where(_id: id).first
    return false if user.blank?
    unless(user.online?)
      user.alert_notify
      # Mailer.test("inside").deliver
    end
  end
end
