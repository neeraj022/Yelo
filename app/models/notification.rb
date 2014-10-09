class Notification
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
  N_CONS = {USER_TAG: 1, CREATE_WALL: 2}
  N_STATUS = {FRESH: 0, SENT: 1, SEEN: 2, SUMMARY: 3}
  ################ instance methods ##############
  def save_notification_status(status)
    self.n_status = Notification::N_STATUS[:SENT]
    self.save
  end

  def notify_obj
     case self.n_type
     when Notification::N_CONS[:USER_TAG]
       Notification.create_wall_obj(self)
     when Notification::N_CONS[:CREATE_WALL]
        Notification.user_tag_obj(self)
     end
  end
  ################ class methods ##################
  class << self
    def save_notify(n_type, n_value, user_id)
      Notification.create(n_type: n_type,
              n_value: n_value, user_id: user_id)
    end

    def save_wall(id)
      wall = Wall.where(_id: id).first
      return false unless wall.present?
      params = self.set_geo_params(wall)
      params[:tag_ids] = [wall.tag_id.to_s]
      params[:type] = "listing"
      listings = Search.query(params).records
      user_ids = listings.map{|l| l.user_id.to_s}.uniq
      user_ids.each do |id|
      	v_hash = {wall_id: wall.id.to_s, tag_name: wall.tag_name, message: wall.message,
        wall_user: wall.wall_owner.name}
        self.save_notify(Notification::N_CONS[:CREATE_WALL], v_hash, id)
      end
    end

    def set_geo_params(obj)
      params = Hash.new
      params[:latitude] = obj.latitude
      params[:longitude] = obj.longitude
      params[:radius] = AppSetting.wall_notify_radius
      params
    end

    def notify
      notifications = Notification.where(n_status: Notification::N_STATUS[:FRESH])
      notifications.each do |n|
        user = n.user
        unless user.can_send_notification?(n.n_value)
          n.save_notification_status(Notification::N_STATUS[:SUMMARY])
          next
        end
        n.save_notification_status(Notification::N_STATUS[:SENT])
        obj = n.notify_obj
        Notification.push_notify(user.platform, [user.push_id], obj)
      end
    end

    def wall_summary_notify
      User.all.each do |u|
        next unless u.can_send_summary_notification?
        c_wall_nfs = u.notifications.where(n_status: Notification::N_STATUS[:SUMMARY], n_type: Notification::N_CONS[:CREATE_WALL])
        next unless c_wall_nfs.present?
        tags_hash = Hash.new
        c_wall_nfs.each do |n|
          v_hash = n.n_value
          n.save_notification_status(Notification::N_STATUS[:SENT])
          if tags_hash.has_key?(v_hash[:tag_name])
            tags_hash[v_hash[:tag_name]] = (tags_hash[v_hash[:tag_name]] += 1)
          else
            tags_hash[v_hash[:tag_name]] = 1 
          end 
        end
        obj = Notification.summary_wall_obj(tags_hash)
        Notification.push_notify(u.platform, [u.push_id], obj)
      end    
    end

    def create_wall_obj(n_obj)
      v_hash = n_obj.n_value
      {collapse_key: "wall", message: "New post for #{v_hash[:tag_name]}: #{v_hash[:message]} created by #{v_hash[:wall_user]}", resource: {name:
       "create wall", dest: {tag: v_hash[:tag_name],  wall_id: v_hash[:wall_id]}}}
    end

    def user_tag_obj(n_obj)
      v_hash = n_obj.n_value
      {collapse_key: "tag", message: "#{v_hash[:tagged_by]} tagged u for #{v_hash[:message]}", resource: {name:
      "tag", dest: {tag: v_hash[:tag_name],  wall_id: v_hash[:wall_id]}}}
    end

    def summary_wall_obj(tags_hash)
     str = "New wall posts "
     tags_hash.each_pair do |k,v| 
         str += "#{v} in #{k},"
     end
     {collapse_key: "summary", message: str, resource: {name:
    "wall summary", dest: nil}}
    end

    def push_notify(platform, push_ids, obj)
      puts obj
      if(platform.downcase == "android")
        self.push_android(push_ids, obj)
      elsif(platform.downcase == "ios")
        # self.push_ios([user.push_token], obj)
      end
    end

    def push_android(ids, obj)
      gcm = GCM.new(Rails.application.secrets.android_api_key)
      registration_ids = ids
      options = {data: obj, collapse_key: obj["collapse_key"]}
      response = gcm.send(registration_ids, options)
      puts response
    end

    def push_ios(ids, msg)
      gcm = GCM.new(Rails.application.secrets.android_api_key)
      registration_ids= ids
      options = {data: {score: "123"}, collapse_key: obj["collapse_key"]}
      response = gcm.send(registration_ids, options)
    end
  end

end
