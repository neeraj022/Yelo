class ListingLink
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :name,        type: String
  field :url,         type: String
  ############# relation #############
  embedded_in :listing 
  ############# validation ###########
  validates :name, :url, presence: true
  validates :url, format: { with: URI.regexp }, if: Proc.new { |a| a.url.present? }
end
