class Cron
  class << self
    def destroy_old_notifications
      # chat = Chat.where(:created_at.lte => 1.month.ago).destroy_all
      notification = Notification.where(:created_at.lte => 1.month.ago).destroy_all
      puts "Notifications destroyed : #{notification}"
      # puts "Chats destroyed: #{chat}"
    end

    def destroy_old_chats
      chat = Chat.where(:created_at.lte => 1.month.ago).destroy_all
      puts "Chats destroyed: #{chat}"
    end

    def gcm_ping
      GcmPing.all.each do |g|
        user = User.where(_id: g.user_id).first
        unless(user.online?)
          user.alert_notify
        end
        g.destroy
      end
    end
  end
end