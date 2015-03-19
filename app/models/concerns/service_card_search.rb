module ServiceCardSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    # Customize the index name
    #
    #index_name [Rails.application.engine_name, Rails.env].join('_')
     index_name ["yelo", "service_card", Rails.env].join('_')

    # Set up index configuration and mapping
    #
    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :title, analyzer: 'standard'
        indexes :created_at, type: "date", format: "date_time"
        indexes :updated_at, type: "date", format: "date_time"
        indexes :loc, type: 'geo_point'
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
      {id: self.id.to_s, tag_id: self.tag_id.to_s, tag_name: self.tag_name, loc: location_coordinates, country: self.country,
       city: self.city, state: self.state, status: self.status, description: self.description, 
       title: self.title, price: self.price, updated_at: self.updated_at, created_at: self.created_at, 
       group_name: self.group_name, group_id: self.group_id.to_s}
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
          query: {},
          filter: {}
        }
      @search_definition[:sort] ||= []
      @search_definition[:sort] << { _at: {card_score: "desc"}}
      @search_definition[:filter][:or] ||= []
      if(query[:latitude].present? && query[:longitude].present?)
         @search_definition[:filter][:or] << {
              geo_distance: {
                  distance: query[:radius].to_s+"km",
                  loc: {
                    lon: query[:longitude].to_f,
                    lat: query[:latitude].to_f
                      }
                  }
            }
         @search_definition[:sort] <<
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
       end
      
       if(query[:q].blank? && query[:tag_id].blank? && query[:group_id].blank? )
          @search_definition[:query] = { match_all: {} }
       else
          @search_definition[:query] = {
            bool: {
                   must: []
                    }
                }
       end
      
       if(query[:tag_id].present?)
         @search_definition[:query][:bool][:must] << {
            term:  { 
              tag_id: query[:tag_id]
            } 
          }
       end
       
       if(query[:group_id].present?)
         @search_definition[:query][:bool][:must] << {
            term:  { 
              group_id: query[:group_id]
            } 
          }
       end

      if(query[:q].present?)
          @search_definition[:query][:bool][:must] << {
            term:{
                title: query[:q]
              }
            }
      end 
           
       if(query[:city].present?)
          @search_definition[:query][:bool][:must] << {
            term:{
                city: query[:city].downcase.strip    
              }
            }
        end  
      
        if(query[:country].present?)
          @search_definition[:query][:bool][:must] << { 
            term: {
                country: query[:country].downcase.strip
               }
            }
        end 
        
        if(query[:status].present?) 
          @search_definition[:query][:bool][:must] << { 
              term: {
                  status: query[:status]
                 }
              }    
        end  
        __elasticsearch__.search(@search_definition)
     end
  end
end




