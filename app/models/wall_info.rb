class WallInfo
  include Mongoid::Document

  field :is_solved,     		   type: Boolean, default: :false
  field :s_name,   		        type: String
  field :s_user_id,     		   type: String
  field :s_mobile_number, 		 type: Integer
  field :s_country_code,     type: Integer
  ############# relations #########################
  embedded_in :wall
end
