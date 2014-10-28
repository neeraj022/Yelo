class ReportAbuse
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id, type: BSON::ObjectId
  ################# relations #################
  belongs_to :abuse_obj, polymorphic: true
  belongs_to :user
end
