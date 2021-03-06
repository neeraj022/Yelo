class Administrator::StatisticsController < Administrator::AdministratorController
  def index
    walls = Wall.where("tagged_users.is_present" => false)
    tag_user_ids = Array.new
    walls.each do |w|
      t = w.tagged_users.where(is_present: false).map{|i| i.mobile_number}
      tag_user_ids.concat( t ) 
    end
    tag_users = User.where(:mobile_number.in => tag_user_ids, mobile_verified: true)
    verified_users =  User.where(mobile_verified: true).count
    date = Date.today
    users_today = User.where(created_at: date.beginning_of_day..date.end_of_day, mobile_verified: true).count
    render json: {tagged_users_from_sms: tag_users.count, verified_users: verified_users, users_today: users_today}
  end

  # # GET /wall/statistics
  # def new_wall_statistics
  #   render "new_wall_dates"
  # end

  # GET /wall/summary
  def new_wall_summary
  	render "new_wall_summary"
  end

  # GET /wall/statistics
  def wall_statistics
  	 if(params[:type] == "month")
       @walls = Wall.collection.aggregate(
         {"$project" => {
            "year" => {"$year" => "$created_at"}, 
            "month" => {"$month" => "$created_at"},
            "tagged_users" => {"$size" => { "$ifNull" => [ "$tagged_users", [] ] }},
            "chat_count" => {"$size" => { "$ifNull" => ["$chat_user_ids", [] ] }}
         }},
         {"$group" => {
            "_id" => {"year" => "$year", "month" => "$month"}, 
            "wall_count" => {"$sum" => 1}, "tag_user_count" => {"$sum" => "$tagged_users"},
            "chat_count" => {"$sum" => "$chat_count"}
         }}
       )
     elsif(params[:type] == "date")
       start_date = Date.parse(params[:start_date])
       end_date = Date.parse(params[:end_date])
       @walls = Wall.collection.aggregate(
         {
          "$match" => { "created_at" => {'$gte' => start_date.beginning_of_day,'$lte' => end_date.end_of_day } } 
         },
         {"$project" => {
            "year" => {"$year" => "$created_at"}, 
            "month" => {"$month" => "$created_at"},
            "date" => {"$dayOfMonth" => "$created_at"},
            "tagged_users" => {"$size" => { "$ifNull" => [ "$tagged_users", [] ] }},
            "chat_count" => {"$size" => { "$ifNull" => ["$chat_user_ids", [] ] }}
         }},
         {"$group" => {
            "_id" => {"date" => "$date", "month" => "$month", "year" => "$year"}, 
            "wall_count" => {"$sum" => 1}, "tag_user_count" => {"$sum" => "$tagged_users"},
            "chat_count" => {"$sum" => "$chat_count"}
         }}
       )
     end
     if request.format == "html"
       render "wall_statistics"
     elsif request.format == "xls"
       @walls_array = Array.new
       @walls.each do |w|
        date = w["_id"]["date"].to_s+"/"+w["_id"]["month"].to_s+"/"+w["_id"]["year"].to_s
        @walls_array << { date: date, :"total number of walls" => w["wall_count"], :"total number of tags" => w["tag_user_count"],
                        :"total number of chats" => w["chat_count"]}
     end
      send_data(@walls_array.to_xls)
    end
  end

  # POST /wall/summary
  def wall_summary
  	start_date = Date.parse(params[:start_date])
  	end_date = Date.parse(params[:end_date])
  	@wall = Wall.where(:created_at => {'$gte' => start_date,'$lte' => end_date})
    render "wall_summary"
  end

  # GET /wall/tags
  def tag_summary
    @walls = Wall.collection.aggregate(
    {"$project" => {
      "tag_name" => "$tag_name", 
      "tagged_users" => {"$size" => { "$ifNull" => [ "$tagged_users", [] ] }},
      "chat_count" => {"$size" => { "$ifNull" => ["$chat_user_ids", [] ] }}
     }},
     {"$group" => {
        "_id" => {"tag" => "$tag_name"}, 
        "post_count" => {"$sum" => 1, }, "tag_user_count" => {"$sum" => "$tagged_users"},
        "chat_count" => {"$sum" => "$chat_count"} 
     }}
    )
    if request.format == "html"
       render "tag_summary"
    elsif request.format == "xls"
     @walls_array = Array.new
     @walls.each do |w|
      @walls_array << { :"total number of walls" => w["post_count"], :"total number of tags" => w["tag_user_count"],
                        :"total number of chats" => w["chat_count"]}
     end
      send_data(@walls_array.to_xls)
    end
  end

  # GET /statistics/users
  def user_summary
    if request.format == "html"
      @users = User.all.allowed.page(params[:page]).per(200)
      render "user_summary"
    elsif request.format == "xls"
      @users = User.all.allowed
      @usr_array = Array.new
      @users.each do |u| 
        referrals = u.statistic.present? ? u.connects_count : 0
        @usr_array << {:name => u.name, :"no of post" => u.walls.count, :"no of chats" => u.chat_logs.count, :"no of referrals" => referrals, :"referred count" => u.total_tagged, :"no of requests" => u.sign_in_count }
      end
       send_data(@usr_array.to_xls)
    end
  end

end


