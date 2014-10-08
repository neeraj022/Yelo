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
  N_STATUS = {FRESH: 0, SENT: 1, SEEN: 2}
  ################ instance methods ##############
  def save_notification_status(status)
    self.n_status = Notification.N_STATUS[:SENT]
    self.save
  end

  def notify_obj
     case self.n_value
     when Notification.N_CONS[:USER_TAG]
       Notification.create_wall_obj(self)
     when Notification.N_CONS[:CREATE_WALL]
        Notification.user_tag_obj(self)
     end
  end
  
  def self.create_wall_obj(n_obj)
    v_hash = n_obj.n_value
    {message: "New post for #{v_hash[:tag_name]}: v_hash[:message] created by #{v_hash[:wall_user]}", resource: {name:
     "create wall", dest: {tag: v_hash[:tag_name],  wall_id: v_hash[:wall_id]}}}
  end

  def self.user_tag_obj(wall)
    v_hash = n_obj.n_value
    {message: "#{v_hash[:tag_user]} tagged u for #{v_hash[:message]}", resource: {name:
    "tag", dest: {tag: v_hash[:tag_name],  wall_id: v_hash[:wall_id]}}}
  end
  ################ class methods ##################
  class << self
    def save_notify(n_type, n_value, user_id)
      Notification.create(n_type: Notification::N_CONS[:USER_TAG],
              n_value: v_hash, user_id: user.id)
    end

    def save_wall(id)
      wall = Wall.where(_id: id).first
      return false unless wall.present?
      params = self.set_geo_params(wall)
      params[:tag_ids] = wall.tag_id.to_s
      tag_name = wall.tag.name
      users = Search.query(params).records
      users.each do |u|
      	v_hash = {wall_id: wall.id.to_s, tag_name: tag_name}
        self.save_notify(Notification::N_CONS[:CREATE_WALL], v_hash, u.id)
      end
    end

    def set_geo_params(obj)
      params = Hash.new
      params[:latitude] = wall.latitude
      params[:longitude] = wall.longitude
      params[:radius] = AppSetting.wall_notify_radius
      params[:type] = obj.class.to_s.downcase
      params
    end

    def notify
      notifications = Notification.where(n_status: Notification.N_STATUS[:FRESH])
      notifications.each do |n|
         user = n.user
         n.save_notification_status(Notification.N_STATUS[:sent])
         next unless user.can_send_notification?(n.n_value)
         obj = n.notify_obj
         if(user.platform.downcase == "android")
           self.push_android([user.push_token], obj)
         elsif(user.platform.downcase == "ios")
           # self.push_ios([user.push_token], obj)
         end
       end
    end
  end

end
