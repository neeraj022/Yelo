class Administrator::StatisticsController < AdministartorController
  def index
    tag_users = Wall.where("tagged_users.is_present" => false)
    tag_user_ids  = tag_users.map{|t| t.user_id.to_s}
    tag_users = User.where(:id.in => tag_user_ids, mobile_verified: true)
    verified_users =  User.where(mobile_verified: true).count
    date = Date.today
    users_today = User.where(created_at: date.beginning_of_day..date.end_of_day, mobile_verified: true).count
    render json: {tagged_users_from_sms: tag_users.count, verified_users: verified_users, users_today: users_today}
  end

  # GET /wall/dates
  def new_wall_statistics
    render "new_wall_dates"
  end

  # GET /wall/summary
  def new_wall_summary
  	render "new_wall_summary"
  end

  # POST /wall/dates
  def wall_statistics
  	start_date = Date.parse(Time.new(params[:year],params[:month]).to_s)
  	end_date = start_date.end_of_month
    render "wall_dates"
  end

  # POST /wall/summary
  def wall_summary
  	start_date = Date.parse(params[:start_date])
  	end_date = Date.parse(params[:end_date])
  	@wall = Wall.where(:created_at => {'$gte' => start_date,'$lte' => end_date})
    render "wall_summary"
  end

end
