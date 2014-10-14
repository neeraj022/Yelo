class WallItem
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

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
  ############### instance methods #########################
  
  def tagged_users
    return [] unless self.tagged_user_ids
    tagged_users = self.wall.tagged_users.where(:_id.in =>  self.tagged_user_ids)
    tagged_users
  end

  def save_tagged_users(tag_users)
    wall = self.wall
    tag_users.each do |t|
      t_usr = create_tag_user(wall, t)
      if t_usr.errors.present?
        return {status: false, error_message: t_usr.errors.messages} unless t_usr.save
      else
        v_hash = {wall_id: wall.id.to_s, commented_by: self.name}
        Notification.save_notify(Notification::N_CONS[:WALL_PIN], v_hash, self.user.id)
      end
    end
    return {status: true}
  end

  def create_tag_user(wall, usr)
    full_num = User.mobile_number_format(usr[:mobile_number])
    mobile_number = full_num[:mobile_number]
    user = User.where(mobile_number: mobile_number).first
    t_usr = wall.tagged_users.new(mobile_number: mobile_number, name: usr[:name],
                                       email: usr[:email])
    if(user.present?)
      user.save_user_tags(wall.tag_id)
      t_usr.user_id = user.id
      t_usr.image_url = user.image_url
      t_usr.name = user.name
      v_hash = {wall_id: wall.id.to_s, tagged_by: self.name, message: wall.message, 
                tag_name: wall.tag_name}
      Notification.save_notify(Notification::N_CONS[:USER_TAG], v_hash, user.id)
    else
      send_wall_tag_sms(wall, full_num)
    end
    self.add_to_set(tagged_user_ids: t_usr.id.to_s)
    t_usr.save
    return t_usr
  end

  def send_wall_tag_sms(wall, full_num)
    @mobile_app_url ||= AppSetting.mobile_app_url
    mobile_number = full_num[:mobile_number]
    country_code = set_country_code(full_num[:country_code])
    sms_log = SmsLog.where(mobile_number: mobile_number, country_code: country_code).first_or_create
    msg = "#{self.name} tagged you in yelo app for a query: #{wall.message},
           Download app at #{@mobile_app_url[:android]}"
    sms_log.send_sms(msg)
  end

  def set_country_code(code)
    if(code.blank?)
      self.user.country_code
    else
      code
    end
  end


end
