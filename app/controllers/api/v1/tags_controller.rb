class Api::V1::TagsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:suggestions, :auto_suggestions, :all_user_tags]
  
  # GET /tags/suggestions
  def suggestions
    if(current_user.present?)
      usr_tag_arr  = current_user.tags
      usr_tag_ids = usr_tag_arr.map{|t| t[:id]}
    end
    usr_tag_ids ||= [] 
    usr_tag_arr ||= []
    tags = Tag.where(:_id.nin => usr_tag_ids).asc(:score)
    tag_arr = tags.map{|t| {id: t.id.to_s, name: t.name}}
    render json: {tags: tag_arr, user_tags: usr_tag_arr}
  rescue => e
    rescue_message(e)
  end

  def create
    @tag = Tag.new(tag_params)
    if @tag.save
      render json: @tag
    else
      render json: {error_message: @tag.errors.full_messages}, status: Code[:error_code]
    end
  rescue => e
    rescue_message(e)
  end

  # GET /users/:user_id/all_tags
  def all_user_tags
    @user =  User.where(_id: params[:user_id]).first
    render json: {user: @user.all_tags} 
  end

  # GET /tags/auto_suggestions
  def auto_suggestions
    tags = Tag.auto_suggestions(params[:q])
    render json: {tags: tags} 
  end

  private
    
    def tag_params
      params.require(:tag).permit(:name)
    end

end
