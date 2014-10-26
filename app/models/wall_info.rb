class WallInfo
  include Mongoid::Document

  field :is_solved,     		        type: Boolean, default: :false
  field :solver_name,   		        type: String
  field :solver_id,     		        type: String
  field :solver_number, 		        type: Integer
  field :solver_country_code,     type: Integer
end
