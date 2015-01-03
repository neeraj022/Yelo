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
            "tagged_users" => {"$size" => { "$ifNull" => [ "$tagged_users", [] ] }}
         }},
         {"$group" => {
            "_id" => {"year" => "$year", "month" => "$month"}, 
            "wall_count" => {"$sum" => 1}, "tag_user_count" => {"$sum" => "$tagged_users"}
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
    render "wall_statistics"
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
   render "tag_summary"
  end

  # GET /users
  def user_summary
    @users = User.all.allowed.page(params[:page]).per(200)
    render "user_summary"
  end

end


