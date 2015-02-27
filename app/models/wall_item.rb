class WallItem
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Common

  field :user_id,             type: BSON::ObjectId
  field :comment,             type: String
  field :image_url,           type: String
  field :up_votes,            type: Integer, default: 0
  field :name,                type: String
  field :abuse_count,         type: Integer, default: 0
  field :tagged_user_ids,     type: Array
  ############### relations ##############################
  embedded_in :wall
  belongs_to :user
  ############### validators ##############################
  validates :user_id,  presence: true
  ################## filters #############################
  ############### instance methods #########################
  def tagged_users
    return [] unless self.tagged_user_ids
    tagged_users = self.wall.tagged_users.where(:_id.in =>  self.tagged_user_ids)
    tagged_users
  end

  def save_tagged_users(tag_users)
    wall = self.wall
    wall_user = wall.user
    tag_users.each do |t|
      t_usr = create_tag_user(wall, t)
      if t_usr.errors.present?
        return {status: false, error_message: t_usr.errors.messages} 
      else
        v_hash = {wall_id: wall.id.to_s, message: wall.message, commented_by: self.name, tag_name: wall.tag_or_group_name}
        if(wall_user.id.to_s != self.user_id.to_s)
          notify = Notification.save_notify(Notification::N_CONS[:WALL_PIN], v_hash, wall_user.id)
          notify.send_notification
          # NotificationWorker.perform_async(notify.id.to_s)
        end
      end
    end
    wall.updated_at = Time.now 
    wall.save
    return {status: true}
  end

  def create_tag_user(wall, usr)
    full_num = User.mobile_number_format(usr[:mobile_number])
    mobile_number = full_num[:mobile_number]
    country_code = set_country_code(full_num[:country_code])
    user = User.allowed.where(mobile_number: mobile_number).first
    t_usr = wall.tagged_users.new(mobile_number: mobile_number, name: usr[:name],
                                      email: usr[:email], country_code: country_code)
    return t_usr unless t_usr.valid?
    if(user.present?)
      t_usr.image_url = user.image_url
      t_usr.user_id = user.id
      t_usr.is_present = true
      t_usr.name = user.name
      v_hash = {wall_id: wall.id.to_s, tagged_by: self.name, message: wall.message, 
                tag_name: wall.tag_or_group_name}
      if (self.user_id.to_s != user.id.to_s)          
        notify = Notification.save_notify(Notification::N_CONS[:USER_TAG], v_hash, user.id)
        # notify = NotificationWorker.perform_async(notify.id.to_s)
        notify.send_notification
      end
    else
      user = User.save_inactive_user(mobile_number, country_code)
      send_wall_tag_email_sms(t_usr, usr[:email], usr[:name]) 
    end
    user.save_user_tags(wall.tag_id, self.user_id) if wall.tag_id.present?
    listing = user.listings.where(tag_id: wall.tag_id).first_or_initialize
    if(!listing.persisted?)
      listing.l_type = 0
      listing.latitude = wall.latitude
      listing.longitude =  wall.longitude
      listing.save
    end
    t_usr.user_id = user.id
    t_usr.save
    self.add_to_set(tagged_user_ids: t_usr.id.to_s)
    return t_usr
  end

  def send_wall_tag_email_sms(usr, email=nil, name=nil)
    @mobile_app_url ||= AppSetting.mobile_app_url
    sms_log = SmsLog.where(mobile_number: usr.mobile_number).first_or_initialize
    sms_log.country_code = usr.country_code
    sms_log.save
    opt = {post_message: wall.message.truncate(100), tagged_by: self.name}
    default_msg = "#{self.name} referred you on yelo - #{wall.message.truncate(100)},
           Download the app here http://app.yelo.red"
    msg = Notification.message_format("tag_sms_msg", opt, default_msg)
    sms_log.send_sms(msg)
    EmailWorker.perform_async("refer", email, wall.message.truncate(100), self.name, name, self.wall.tag_or_group_name, self.wall.wall_owner.name)
  rescue => e
    false
  end

  def set_country_code(code)
    if(code.blank?)
      self.user.country_code
    else
      code
    end
  end


end
