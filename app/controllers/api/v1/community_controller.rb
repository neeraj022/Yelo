class Api::V1::CommunityController < Api::V1::BaseController
  
  # GET /suggestions?type=keyword
  def suggestions
  	@words = []
    case params[:type]
    when "keywords"
      @words =  Keyword.where(name: /#{params[:q]}/, tag_id: params[:tag_id])
    when "tags"
      @words =  Tag.where(name: /#{params[:q]}/)
    end
    render json: @words, root: "suggestions"
  rescue => e
    rescue_message(e)
  end

  # GET /tag_list/group_id
  def tag_list
  	@list = Array.new
    tags = Tag.where(group_id: params[:group_id])
    tags.each do |t|
      words = Keyword.where(tag_id: t.id).limit(10)
      words = Code.serialized_json(words.to_a)
      @list << {name: t.name, id: t.id.to_s, keywords: words}
    end
    render json: {tags: @list}
  end
   
   # GET /group_list
   def group_list
     @groups = Group.where(status: true)
     render json: @groups, root: :groups
   end

   # GET /top_tags
   def top_tags
     @list = Array.new
     @tags = Listing.collection.aggregate(
       {"$group" => {
         "_id" => {"tag_id" => "$tag_id"}, 
          "tag_count" => {"$sum" => 1, } 
       }},
       { "$sort" => { "tag_count" => -1 } }
      )
     @tags.each do |t|
       tag = Tag.where(_id: t["_id"]["tag_id"]).first
       next if tag.blank?
       words = Keyword.where(tag_id: tag.id).limit(10)
       words = Code.serialized_json(words.to_a)
       @list << {name: tag.name, id: tag.id.to_s, keywords: words}
     end
     render json: {tags: @list}
   end

end


