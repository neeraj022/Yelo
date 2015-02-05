class ListingLink
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :name,        type: String
  field :url,         type: String
  ############# relation #############
  embedded_in :listing 
  ############# validation ###########
  # validates :name, :url, presence: true
  validates :url, format: { with: URI.regexp }, if: Proc.new { |a| a.url.present? }

  def image_url
    domain = ListingLink.extract_domain(self.url)
    image_url = domain+".png"
    if Rails.application.assets.find_asset image_url
      ActionController::Base.helpers.asset_path(image_url)
    else
      ActionController::Base.helpers.asset_path("www.png")
    end
  end

  def self.extract_domain(url)
    # /^(http:\/\/)*(www.)*([a-zA-Z0-9.-]*)\/?.*/i
    if domain = url.match(/^(http:\/\/)*(www.)*([a-zA-Z0-9.-]*)\/?.*/i)
      domain = domain[3].split('.')
      domain[0]
    end
  end

end
