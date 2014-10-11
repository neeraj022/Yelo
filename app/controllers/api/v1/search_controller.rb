class Api::V1::SearchController < ApplicationController
  before_action :set_search_params
  
  # GET /search
  def search
  	@results  = Search.query(@params).page(params[:page]).per(params[:per]).records
    render json: @results
  end


  private
    def set_search_params
      @params = {latitude: params[:latitude].to_f, longitude: params[:longitude].to_f,
                 city: params[:city], country: params[:country],
                 type: params[:type], tag_ids: params[:tag_ids]}
      params[:radius] ||= 20
      params[:per] ||= 20
      @params[:radius] = params[:radius].to_i 
      @params[:per]  = params[:per].to_i
      @params[:tag_ids] = set_tag_ids
    end 

    def set_tag_ids
      if(current_user.present? && params[:tag_ids].blank?)
        current_user.wall_tags
      else
        params[:tag_ids]
      end
    end

end
