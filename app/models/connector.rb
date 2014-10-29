class Connector
  include Mongoid::Document
  
  field :user_id,      type: BSON::ObjectId
  field :user_tag_id,  type: BSON::ObjectId
  ########## relations ##################
  belongs_to :user_tag
  belongs_to :user
  ########## filters #####################
  before_create :increment_connector_count
  ########## methods #####################
  def increment_connector_count
   statistic = self.user.statistic
   statistic.connects = (statistic.connects += 1)
   statistic.save
  end

end
