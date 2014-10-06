module UserSearch
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
        indexes :city, analyzer: 'standard'
        indexes :country, analyzer: 'standard'
        indexes :name, analyzer: 'standard'
        indexes :state, analyzer: 'standard'
        indexes :loc, type: 'geo_point'
        indexes :statistic do
          indexes :rating_score, index: 'not_analyzed', type: 'integer'
        end
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
       {id: self.id.to_s, loc: self.loction_coordinates, name: self.name}
    end

    # Search in title and content fields for `query`, include highlights in response
    #
    # @param query [String] The user query
    # @return [Elasticsearch::Model::Response::Response]
    #
    def self.search(query, options={})
      # Prefill and set the filters (top-level `filter` and `facet_filter` elements)
      #
      __set_filters = lambda do |key, f|

        @search_definition[:filter][:and] ||= []
        @search_definition[:filter][:and]  |= [f]

        @search_definition[:facets][key.to_sym][:facet_filter][:and] ||= []
        @search_definition[:facets][key.to_sym][:facet_filter][:and]  |= [f]
      end

      @search_definition = {
          query: {},
          filter: {
              geo_distance: {
                  distance: query[:radius].to_s+"km",
                  loc: {
                    lon: query[:longitude].to_f,
                    lat: query[:latitude].to_f
                      }
                
                  }
            },

          sort: [
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
        }

         if(query[:tag_id].present?)
            @search_definition[:query] = {
              match:  { tag_id: query[:tag_id]} 
            }
        else
          @search_definition[:query] = { match_all: {} }
        end
        __elasticsearch__.search(@search_definition)
     end
  end
end
