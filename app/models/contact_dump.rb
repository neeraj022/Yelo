class ContactDump
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :contacts,   type: Array
  field :status,     type: Integer, default: 0
  field :user_id,    type: BSON::ObjectId
  field :error_msg,  type: String

  CONTACT_DUMP_CONS = {FRESH: 0,  PROCESSED: 1, ERROR: 2}
end
