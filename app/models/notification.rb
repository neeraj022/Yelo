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
  N_CONS = {USER_TAG: 1, WALL: 2}
  N_STATUS = {FRESH: 0, SENT: 1, SEEN: 2}

  ################ class methods ##################
  class << self
    def save_notify(n_type, n_value, user_id)
      Notification.create(n_type: Notification::N_CONS[:USER_TAG],
              n_value: v_hash, user_id: user.id)
    end
  end

end
