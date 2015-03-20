class Api::V1::SearchController < Api::V1::BaseController
  before_action :set_search_params
  after_action :send_welcome_message, only: [:search]
  
  # GET /search
  def search
  	@results  = Search.query(@params).page(params[:page]).per(params[:per]).records
    @results = @results.to_a
    if(@results.present?)
      render json: @results.to_a
    else
      show_active_cities
    end
  rescue => e
     rescue_message(e) 
  end

  def show_active_cities
    str = "We are curretly active only in the following cities \n"
    str += "(You can change your location under profile settings) \n"
    # cities = Wall.collection.aggregate("$group" => { "_id" => "$city", count: {"$sum" =>  1} }).select{|w| w["count"] > 5}.map{|w| w["_id"]}
    cities = Wall.collection.aggregate("$group" => {_id: {city: "$city", country: "$country"}, count: {"$sum" =>  1} }).select{|w| w["count"] > 5}.map{|w| w["_id"]["city"]}
    cities.each do |c|
      str += "#{c.capitalize}\n"
    end
    render json: {search:[], message: str}
  end

  private
    def set_search_params
      case params[:type]
      when "wall"
        wall_search_params
      when "service_card"
        service_card_params
      end
    end

    def wall_search_params
      @params = {city: params[:city], country: params[:country],
                 type: params[:type], tag_ids: params[:tag_ids],
                 or_city: params[:or_city], or_country: params[:or_country]}
      @params[:status] = true unless params[:status].present?
      @params[:latitude] = params[:latitude].to_f if params[:latitude].present?
      @params[:longitude] = params[:longitude].to_f if params[:longitude].present?
      params[:radius] ||= 25
      params[:per] ||= 20
      @params[:radius] = params[:radius].to_i 
      @params[:per]  = params[:per].to_i
      @params[:tag_ids] = set_tag_ids
      @params[:post] = params[:post] if params[:post].present?
    end 

    def service_card_params
       @params = {city: params[:city], country: params[:country],
                 type: params[:type], tag_id: params[:tag_id], group_id: params[:group_id],
                 title: params[:title]}
      @params[:status] = 0
      @params[:latitude] = params[:latitude].to_f if params[:latitude].present?
      @params[:longitude] = params[:longitude].to_f if params[:longitude].present?
      params[:radius] ||= 25
      @params[:radius] = params[:radius].to_i
      params[:per] ||= 20
    end

    def set_tag_ids
      if(current_user.present? && params[:tag_ids].blank? && params[:user_tag].present?)
        current_user.wall_tags
      else
        params[:tag_ids]
      end
    end

    def send_welcome_message
      if(current_user.present? && !current_user.w_msg_sent)
        current_user.send_welcome_message
        current_user.w_msg_sent = true
        current_user.save
      end
    end

end
