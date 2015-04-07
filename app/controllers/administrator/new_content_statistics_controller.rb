class Administrator::NewContentStatisticsController  < Administrator::AdministratorController
  
  def index
  	 @date = Date.today
  	 @day_query = "{created_at: @date.beginning_of_day..@date.end_of_day}"
  	 @week_query = "{created_at: @date.beginning_of_week..@date.end_of_day}"
  	 @month_query = "{created_at: @date.beginning_of_month..@date.end_of_month}"
     ######################### day ###########################################
     @day_listings = Listing.where(eval(@day_query))
     @day_users =  User.where(eval(@day_query)).where(mobile_verified: true)
     @day_chats = Chat.where(eval(@day_query))
     @day_posts = Wall.where(eval(@day_query))
     @day_service_cards = ServiceCard.where(eval(@day_query))
     ##################### week  #######################################
     @week_listings = Listing.where(eval(@week_query))
     @week_users =  User.where(eval(@week_query)).where(mobile_verified: true)
     @week_chats = Chat.where(eval(@week_query))
     @week_posts = Wall.where(eval(@week_query))
     @week_service_cards =  ServiceCard.where(eval(@week_query))
     ################## month  #######################################
     @month_listings = Listing.where(eval(@month_query))
     @month_users =  User.where(eval(@month_query)).where(mobile_verified: true)
     @month_chats = Chat.where(eval(@month_query))
     @month_posts = Wall.where(eval(@month_query))
     @month_service_cards =  ServiceCard.where(eval(@month_query))
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
