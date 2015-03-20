class Search
  class << self
    def query(params)
      case params[:type]
      when "listing"
      	Search.search_listings(params)
      when "user"
      	Search.search_users(params)
      when "wall"
      	Search.search_walls(params)
      when "service_card"
        Search.search_service_cards(params)
      else
      	""
      end
    end
    
    def search_listings(params)
      Listing.search(params)
    end

    def search_users(params)
      User.search(params)
    end
    
    def search_walls(params)
      Wall.search(params)
    end

    def search_service_cards(params)
      ServiceCard.search(params)
    end

  end
end
