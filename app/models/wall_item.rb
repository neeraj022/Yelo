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
  ############### validators ##############################
  validates :user_id,  presence: true
  ############### instance methods #########################
  
  def tagged_users
    return [] unless self.tagged_user_ids
    tagged_users = self.wall.tagged_users.where(:_id.in =>  self.tagged_user_ids)
    tagged_users
  end

  def save_tagged_users(tag_users)
    mobile_app_url = AppSetting.mobile_app_url
    wall = self.wall
    tag_users.each do |t|
      number = User.mobile_number_format(t[:mobile_number])
      mobile_number = number[:mobile_number]
      country_code = number[:country_code]
      user = User.where(mobile_number: mobile_number).first
      t_usr = wall.tagged_users.new(mobile_number: mobile_number, name: t[:name],
                                         email: t[:email])
      if(user.present?)
        user.save_user_tags(wall.tag_id)
        t_usr.user_id = user.id
        t_usr.image_url = user.image_url
        t_usr.name = user.name
        v_hash = {wall_id: wall.id, tagged_by: self.name, message: wall.message, 
                  tag_name: wall.tag_name}
        Notification.save_notify(Notification::N_CONS[:USER_TAG], v_hash, user.id)
      else
        sms_log = SmsLog.where(mobile_number: mobile_number, country_code: country_code).first_or_create
        msg = "#{self.name} tagged you in yelo app for a query: #{wall.message},
               Download app at #{mobile_app_url[:android]}"
        sms_log.send_sms(msg)
      end
      return {status: false, error_message: t_usr.errors.messages} unless t_usr.save
      self.add_to_set(tagged_user_ids: t_usr.id.to_s)
    end
    return {status: true}
  end

end
