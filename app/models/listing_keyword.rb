class ListingKeyword
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :name,        type: String
  field :keyword_id,  type: String
  field :word_id,     type: String   
  ############# relation #############
  embedded_in :listing 
end

