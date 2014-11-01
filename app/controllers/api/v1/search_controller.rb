class Api::V1::SearchController < Api::V1::BaseController
  before_action :set_search_params
  after_action :send_welcome_message, only: [:search]
  
  # GET /search
  def search
  	@results  = Search.query(@params).page(params[:page]).per(params[:per]).records
    render json: @results.to_a
  rescue => e
     rescue_message(e) 
  end

  private
    def set_search_params
      @params = {city: params[:city], country: params[:country],
                 type: params[:type], tag_ids: params[:tag_ids],
                 or_city: params[:or_city], or_country: params[:or_country]}
      @params[:status] = true unless params[:status].present?
      @params[:latitude] = params[:latitude].to_f if params[:latitude].present?
      @params[:longitude] = params[:longitude].to_f if params[:longitude].present?
      params[:radius] ||= 20
      params[:per] ||= 20
      @params[:radius] = params[:radius].to_i 
      @params[:per]  = params[:per].to_i
      @params[:tag_ids] = set_tag_ids
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
        User.send_welcome_message(current_user.id.to_s)
        current_user.w_msg_sent = true
        current_user.save
      end
    end

end
