module Common
  extend ActiveSupport::Concern

  included do
  	attr_accessor :tmp_id
  end

end