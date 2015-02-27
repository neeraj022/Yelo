class GcmChatWorker
  include Sidekiq::Worker
  sidekiq_options queue: "gcm_chat", retry: false

  def perform(id)
    user = User.where(_id: id).first
    puts "after 5 mins"
    Mailer.test("after 5 mins #{user.name}").deliver
    return false if user.blank?
    unless(user.online?)
      user.alert_notify
      puts "ping sent"
      # Mailer.test("inside").deliver
    end
  end
end
