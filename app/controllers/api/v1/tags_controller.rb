class Api::V1::TagsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:suggestions]
  
  # GET /tags/suggestions
  def suggestions
    if(current_user.present?)
      usr_tag_arr  = current_user.tags
      usr_tag_ids = usr_tag_arr.map{|t| t[:id]}
    end
    usr_tag_ids ||= [] 
    usr_tag_arr ||= []
    tags = Tag.where(:_id.nin => usr_tag_ids).asc(:score).limit(5)
    tag_arr = tags.map{|t| {id: t.id.to_s, name: t.name}}
    render json: {tags: tag_arr, user_tags: usr_tag_arr}
  rescue => e
    rescue_message(e)
  end

end
