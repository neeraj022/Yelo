class WallChatUser
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id,         type: BSON::ObjectId
   
  ##### relations ##############
  embedded_in :wall

  def user
    @user = User.where(_id: self.user_id).first
  end

  def name
    user.name
  end

  def image_url
    user.image_url
  end

end
