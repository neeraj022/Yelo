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
    tagged_users = self.wall.tagged_users.where(:_id.in =>  self.tagged_user_ids)
    tagged_users
  end

  def save_tagged_users(tag_users)
    wall = self.wall
    tag_users.each do |t|
      user = User.where(mobile_number: t[:mobile_number]).first
      mobile_number = User.mobile_number_format(t[:mobile_number])[:mobile_number]
      t_usr = wall.tagged_users.new(mobile_number: mobile_number, name: t[:name],
                                         email: t[:email])
      if(user.present?)
        user.save_user_tags(wall.tag_id)
        t_usr.user_id = user.id
        t_usr.image_url = user.image_url
        t_usr.name = user.name
      end
      return {status: false, error_message: t_usr.errors.messages} unless t_usr.save
      self.add_to_set(tagged_user_ids: t_usr.id.to_s)
    end
    return {status: true}
  end

end
