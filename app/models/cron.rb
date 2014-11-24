class Cron
  class << self
    def destroy_old_notifications_and_chat
      chat = Chat.where(:created_at.lte => 1.month.ago).destroy_all
      notification = Notification.where(:created_at.lte => 1.month.ago).destroy_all
      puts "Notifications destroyed : #{notification}"
      puts "Chats destroyed: #{chat}"
    end
  end
end