module WallSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    # Customize the index name
    #
    index_name [Rails.application.engine_name, Rails.env].join('_')

    # Set up index configuration and mapping
    #
    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :created_at, type: 'date'
        indexes :city, analyzer: 'standard'
        indexes :country, analyzer: 'standard'
        indexes :state, analyzer: 'standard'
        indexes :loc, type: 'geo_point'
        indexes :tag_id, analyzer: 'standard'
        # indexes :message, type: 'multi_field' do
        #   indexes :message
        #   indexes :msg_words, analyzer: 'keyword'
        # end
      end
    end

    # Set up callbacks for updating the index on model changes
    #
    # after_commit lambda { Indexer.perform_async(:index,  self.class.to_s, self.id) }, on: :create
    # after_commit lambda { Indexer.perform_async(:update, self.class.to_s, self.id) }, on: :update
    # after_commit lambda { Indexer.perform_async(:delete, self.class.to_s, self.id) }, on: :destroy
    # after_touch  lambda { Indexer.perform_async(:update, self.class.to_s, self.id) }

    # Customize the JSON serialization for Elasticsearch
    #
    def as_indexed_json(options={})
      {tag_id: self.tag_id.to_s, loc: location_coordinates, country: self.country,
       city: self.city, state: self.state, created_at: self.created_at}
    end

    # Search in title and content fields for `query`, include highlights in response
    #
    # @param query [String] The user query
    # @return [Elasticsearch::Model::Response::Response]
    #
    def self.search(query)
      # Prefill and set the filters (top-level `filter` and `facet_filter` elements)
      #
      __set_filters = lambda do |key, f|

        @search_definition[:filter][:and] ||= []
        @search_definition[:filter][:and]  |= [f]

        @search_definition[:facets][key.to_sym][:facet_filter][:and] ||= []
        @search_definition[:facets][key.to_sym][:facet_filter][:and]  |= [f]
      end


      @search_definition = {
          query: {}
        }

      if(query[:latitude].present? && query[:longitude].present?)
         @search_definition[:filter] = {
              geo_distance: {
                  distance: query[:radius].to_s+"km",
                  loc: {
                    lon: query[:longitude].to_f,
                    lat: query[:latitude].to_f
                      }
                  }
               }
          @search_definition[:sort] = 
                [
                    {
                        _geo_distance: {
                            loc: {
                                lon: query[:longitude].to_f,
                                lat: query[:latitude].to_f
                                  },
                            order: "asc",
                            unit: "km"
                         }
                    }
                ]
            
       end
       
       if(query[:tag_id].present?)
         @search_definition[:query][:bool][:should] ||= []  
          @search_definition[:query][:bool][:should] << {
            match:  { tag_id: query[:tag_id],
              operator: 'and'
            } 
          }
       end
       if(query[:city].present? && query[:country].present?)
          @search_definition[:query][:bool][:should] << { match:{
            city: query[:city].downcase,
            operator: 'and' }
            }
           
          @search_definition[:query][:bool][:should] << { match: {
            country: query[:country].downcase,
            operator: 'and'
               }
            }
       end
       if(query[:city].blank? && query[:tag_id].blank?)
          @search_definition[:query] = { match_all: {} }
       end
        __elasticsearch__.search(@search_definition)
     end
  end
end

