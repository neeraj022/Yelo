class PushRecord
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :user_id,   type: BSON::ObjectId
  field :n_type,    type: Integer
  field :n_value,   type: Hash
  field :n_status,  type: Integer, default: 0
  ################### relation ###################
  belongs_to :user 
  ################  constants ####################
  N_CONS = {USER_TAG: 1, CREATE_WALL: 2, WALL_PIN: 3, CONTACT_WALL: 4, WALL_COMMENT: 5}
  N_STATUS = {FRESH: 0, SENT: 1, SEEN: 2, SUMMARY: 3}
  ################ instance methods ##############
  def save_notification_status(status)
    self.n_status = status
    self.save
  end

  def notify_obj
    case self.n_type
    when PushRecord::N_CONS[:USER_TAG]
      PushRecord.user_tag_obj(self)
    when PushRecord::N_CONS[:CREATE_WALL]
      PushRecord.create_wall_obj(self)
    when PushRecord::N_CONS[:WALL_PIN]
      PushRecord.wall_tag_obj(self)
    when PushRecord::N_CONS[:CONTACT_WALL]
       PushRecord.contact_wall_obj(self)
    when PushRecord::N_CONS[:WALL_COMMENT]
      PushRecord.wall_comment_obj(self)
    end
  end

  def send_notification
    user = self.user
    return false unless user.push_id.present?
    unless user.can_send_notification?(self.n_type)
      self.save_notification_status(PushRecord::N_STATUS[:SUMMARY])
      return false
    end
    self.save_notification_status(PushRecord::N_STATUS[:SENT])
    obj = self.notify_obj
    PushRecord.push_notify(user.platform, [user.push_id], obj)
  end
 
  ################ class methods ##################
  class << self
    def save_notify(n_type, n_value, user_id, status=nil)
      status ||= PushRecord::N_CONS[:FRESH]
     PushRecord.create(n_type: n_type,n_value: n_value, user_id: user_id, n_status: status)
    end

    def save_wall(id)
      wall = Wall.where(_id: id).first
      return false unless wall.present?
      params = self.set_geo_params(wall)
      params[:tag_id] = wall.tag_id.to_s
      # params[:keyword_ids] = wall.keyword_ids
      params[:type] = "listing"
      params[:radius] = 25
      params[:size] = 10000
      listings = Search.query(params).records
      user_ids = listings.map{|l| l.user_id.to_s}.uniq
      user_ids.delete(wall.user_id.to_s)
      v_hash = {wall_id: wall.id.to_s, tag_name: wall.tag_name, message: wall.message,
        wall_user: wall.wall_owner.name}
      notify_obj = self.create_wall_obj(v_hash)
      self.send_new_wall_notifications(user_ids, notify_obj)
      # user_ids.each do |id|
      #   self.save_notify(Notification::N_CONS[:CREATE_WALL], v_hash, id, Notification::N_STATUS[:SUMMARY])
      # end
    end

    def set_geo_params(obj)
      params = Hash.new
      params[:latitude] = obj.latitude
      params[:longitude] = obj.longitude
      params[:radius] = AppSetting.wall_notify_radius
      params
    end

    def send_daily_notification()
      users = User.allowed.where(:updated_at.lte => 1.days.ago)
      return if users.count == 0
      users.each do |u|
        listings = u.listings
        next if listings.blank?
        listing = listings.last
        params = self.set_geo_params(listing)
        params[:type] = "wall"
        params[:size] = 10
        params[:date_gte] = 1.days.ago
        params[:status] = true
        walls = Search.query(params).records
        count = walls.count
        next if count == 0
        last = (walls.count - 1)
        wall = walls[rand(0..last)]
        str =  "New Post: #{wall[:message].truncate(100)}"
        obj = {collapse_key: "wall", message: str, resource: {name:
       "yelo", dest: {tag: wall.tag_name,  wall_id: wall.id.to_s}}}
        u.touch
        next if (u.platform.blank? || u.push_id.blank?)
        PushRecord.push_notify(u.platform, [u.push_id], obj) 
      end
    end

    def send_new_wall_notifications(user_ids, notify_obj)
      users = User.where(:_id.in => user_ids)
      android_push_ids = Array.new
      ios_push_ids = Array.new
      users.each do |u|
        if(u.platform == "android")
          android_push_ids << u.push_id if u.push_id.present?
        elsif(u.platform == "ios")
          ios_push_ids << u.push_id if u.push_id.present?
        end
      end
      PushRecord.push_notify("android", android_push_ids, notify_obj) if android_push_ids.present?
    end

    def send_single_notification(user_id, notify_obj)
      user = User.where(:_id => user_id).first
      return "" if user.blank?
      android_push_ids = Array.new
      ios_push_ids = Array.new
      if(user.platform == "android")
        android_push_ids << user.push_id if user.push_id.present?
      elsif(user.platform == "ios")
        ios_push_ids << user.push_id if user.push_id.present?
      end
      PushRecord.push_notify("android", android_push_ids, notify_obj) if android_push_ids.present?
      PushRecord.push_notify("ios", ios_push_ids, notify_obj) if ios_push_ids.present?
    end


    def send_notifications(user_ids, notify_obj)
      users = User.where(:_id.in => user_ids)
      android_push_ids = Array.new
      ios_push_ids = Array.new
      users.each do |u|
        if(u.platform == "android")
          android_push_ids << u.push_id if u.push_id.present?
        elsif(u.platform == "ios")
          ios_push_ids << u.push_id if u.push_id.present?
        end
      end
      PushRecord.push_notify("android", android_push_ids.uniq, notify_obj) if android_push_ids.present?
      PushRecord.push_notify("ios", ios_push_ids.uniq, notify_obj) if ios_push_ids.present?
    end

    def notify
      puts "started quick notification"
      notifications = PushRecord.where(n_status: PushRecord::N_STATUS[:FRESH])
      notifications.each do |n|
        begin
          n.send_notification
        rescue => e
          n.destroy
        end
      end
    end

    def wall_summary_notify
      puts "started summary notification"
      User.allowed.each do |u|
        next unless u.can_send_summary_notification?
        c_wall_nfs = u.notifications.where(n_status: PushRecord::N_STATUS[:SUMMARY], n_type: PushRecord::N_CONS[:CREATE_WALL])
        next unless c_wall_nfs.present?
        tags_hash = Hash.new
        c_wall_nfs.each do |n|
          begin
            v_hash = n.n_value
            n.save_notification_status(PushRecord::N_STATUS[:SENT])
            if tags_hash.has_key?(v_hash[:tag_name])
              tags_hash[v_hash[:tag_name]] = (tags_hash[v_hash[:tag_name]] += 1)
            else
              tags_hash[v_hash[:tag_name]] = 1 
            end
          rescue => e 
            n.destroy
          end
        end
        next unless u.push_id.present?
        obj = PushRecord.summary_wall_obj(tags_hash)
        PushRecord.push_notify(u.platform, [u.push_id], obj)
        u.update_attributes(last_notify_sent_at: Time.now)
      end    
    end

    def save_contact_wall(wall_id)
      wall = Wall.where(_id: wall_id).first
      user = wall.user
      contacts = user.app_contacts
      v_hash = {wall_id: wall.id.to_s, created_by: user.name, message: wall.message, 
                tag_name: wall.tag_name, created_number: user.mobile_number}
      contacts.each do |c|
        notification = PushRecord.save_notify(PushRecord::N_CONS[:CONTACT_WALL], v_hash, c.id)
        notification.send_notification
      end
    end

    def create_wall_obj(n_obj)
      v_hash = (n_obj.class.name == "PushRecord") ? n_obj.n_value : n_obj
      opt = {tag_name: v_hash[:tag_name], post_message: v_hash[:message]}
      default_msg =  "New post in your interest ##{v_hash[:tag_name]} - #{v_hash[:message].truncate(100)}"
      str = self.message_format("interest_post_msg", opt, default_msg)
      {collapse_key: "wall", message: str, resource: {name:
       "yelo", dest: {tag: v_hash[:tag_name],  wall_id: v_hash[:wall_id]}}}
    end

    def contact_wall_obj(n_obj)
      v_hash = n_obj.n_value
      opt = {post_owner: v_hash[:created_by], tag_name: v_hash[:tag_name], post_message: v_hash[:message]}
      default_msg =  "#{v_hash[:created_by]} posted on yelo: #{v_hash[:message].truncate(100)}"
      str = self.message_format("contact_post_msg", opt, default_msg)
      {collapse_key: "contact_wall", message: str, resource: {name:
       "yelo", dest: {tag: v_hash[:tag_name],  wall_id: v_hash[:wall_id]}}}
    end

    def user_tag_obj(n_obj)
      v_hash = n_obj.n_value
      opt = {tagged_by: v_hash[:tagged_by], tag_name: v_hash[:tag_name], post_message: v_hash[:message]}
      default_msg =  "#{v_hash[:tagged_by]} referred you on - #{v_hash[:message].truncate(100)}"
      str = self.message_format("post_tag_msg", opt, default_msg)
      {collapse_key: "tag", message: str, resource: {name:
      "Referred on yelo", dest: {tag: v_hash[:tag_name],  wall_id: v_hash[:wall_id],datetime: DateTime.now.strftime("%m-%d-%Y %H:%M %p")}}}
    end

    def wall_tag_obj(n_obj)
      v_hash = n_obj.n_value
      opt = {commented_by: v_hash[:commented_by], tag_name: v_hash[:tag_name], post_message: v_hash[:message]}
      default_msg =  "You have a new referral from #{v_hash[:commented_by]} for your ##{v_hash[:tag_name]} post"
      str = self.message_format("post_follow_msg", opt, default_msg)
      {collapse_key: "pin", message: str , resource: {name:
      "Referral on yelo", dest: {tag: v_hash[:tag_name],  wall_id: v_hash[:wall_id], datetime: DateTime.now.strftime("%m-%d-%Y %H:%M %p")}}}
    end

    def wall_comment_obj(n_obj)
      v_hash =  (n_obj.kind_of? PushRecord) ? n_obj.n_value : n_obj
      #str =  "#{v_hash[:commented_by]}: #{v_hash[:comment].truncate(100)}"
      str = "#{v_hash[:commented_by]} also commented on - #{v_hash[:post_tag]}"
      {collapse_key: "comment", message: str , resource: {name:
      "New Comment", dest: {wall_id: v_hash[:wall_id],tag: v_hash[:sub_category],datetime: DateTime.now.strftime("%m-%d-%Y %H:%M %p")}}}
    end

    def message_format(type, opt={}, default_msg=nil)
      str = AppSetting.first.send(type)
      return default_msg unless str.present?
      opt.each_pair do  |k, v|
        str.gsub!(/\[#{k.to_s}\]/, v.to_s.truncate(140))
      end
      str
    end

    def send_comment_notifications(wall_id, comment_id, user_id)
       wall = Wall.where(_id: wall_id).first
       return if wall.blank?
       comment = wall.comments.where(_id: comment_id).first
       user = User.find(user_id)
       v_hash = {wall_id: wall.id.to_s, commented_by: user.name, post_tag: wall.message,sub_category: wall.tag_name} 
       user_ids = wall.comments.map{|c| c.user_id.to_s}.uniq
       user_ids.delete(user.id.to_s)
       user_ids.delete(wall.user_id.to_s)
       return if user_ids.blank?
       obj = PushRecord.wall_comment_obj(v_hash)
      obj1 = {:collapse_key=>"comment", :message=> "You have a new comment from #{user.name} on - #{wall.message}", :resource=>{:name=>"New Comment", :dest=>{:wall_id=>wall.id.to_s,:tag => wall.tag_name,datetime: DateTime.now.strftime("%m-%d-%Y %H:%M %p")}}}
      unless wall.user_id.to_s === user.id.to_s
        user_id =  wall.user_id.to_s
	response1 = PushRecord.send_single_notification(user_id,obj1)
      end
      response =  PushRecord.send_notifications(user_ids, obj)
    end
    
    def summary_wall_obj(tags_hash)
      str = "Today on yelo - "
      tags_hash.each_pair do |k,v| 
          str += "#{v} in #{k}, "
      end
      str = str.strip.chomp(",")
      {collapse_key: "summary", message: str, resource: {name:
     "yelo", dest: nil}}
    end

    def push_notify(platform, push_ids, obj)
      # puts obj
      if(platform.downcase == "android")
        response = self.push_android(push_ids, obj)
      elsif(platform.downcase == "ios")
        response = self.push_ios(push_ids,obj.to_json)
      end
      response
    end

    def push_android(ids, obj)
      #return "" unless Rails.env == "production"
      gcm = GCM.new(Rails.application.secrets.android_api_key)
      # options = {data: {payload: obj.to_json}, collapse_key: obj["collapse_key"]}
      options = {data: {payload: obj.to_json}}
      response = gcm.send(ids, options)
      response
    end

     def push_ios(ids, obj)
    #   gcm = GCM.new(Rails.application.secrets.android_api_key)
    #   registration_ids= ids
    #   options = {data: {score: "123"}, collapse_key: obj["collapse_key"]}
    #   response = gcm.send(registration_ids, options)
      objnew = ActiveSupport::JSON.decode(obj.gsub(/:([a-zA-z])/,'\\1').gsub('=>', ' : '))
       message = objnew["message"] 
       ids.each do |id|
         n = APNS::Notification.new(id.to_s, message)
         otherjson = {:collapse_key => objnew["collapse_key"],:resource => {:name => objnew["resource"]["name"],:dest =>{:wall_id => objnew["resource"]["dest"]["wall_id"],:tag => objnew["resource"]["dest"]["tag"],:datetime => objnew["resource"]["dest"]["datetime"]}}}
         response = APNS.send_notification(id.to_s, :alert => message, :badge => 1, :sound => 'default' ,:other => otherjson)
	end
     end
  end

end

