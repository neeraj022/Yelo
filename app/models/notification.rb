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
  end

end
