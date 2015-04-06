class Administrator::NewContentStatisticsController  < Administrator::AdministratorController
  
  def index
  	 @date = set_date
  	 @date_query = "{created_at: @date[:from]..@date[:to]}"
     @listings = Listing.where(eval(@date_query))
     @users =  User.where(eval(@date_query)).where(mobile_verified: true)
     @chats = Chat.where(eval(@date_query))
     @posts = Wall.where(eval(@date_query))
     @service_cards =  ServiceCard.where(eval(@date_query))
  end

  def set_date
  	date = Date.today
    date_hash = case params[:type]
			    when "day"
			      {from: date.beginning_of_day, to: date.end_of_day}
			    when "week"
			      {from: date.beginning_of_week, to: date.end_of_week}
			    when "month"
			      {from: date.beginning_of_month, to: date.end_of_month}
			    else
                  {from: date.beginning_of_day, to: date.end_of_day}
			    end
    date_hash
  end



end
