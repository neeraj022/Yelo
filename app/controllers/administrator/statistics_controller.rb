class Administrator::StatisticsController < ApplicationController
  def index
    tag_users = Wall.where("tagged_users.is_present" => false)
    tag_user_ids  = tag_users.map{|t| t.user_id.to_s}
    tag_users = User.where(:id.in => tag_user_ids, mobile_verified: true)
    verified_users =  User.where(mobile_verified: true).count
    date = Date.today
    users_today = User.where(created_at: date.beginning_of_day..date.end_of_day, mobile_verified: true).count
    render json: {tagged_users_from_sms: tag_users.count, verified_users: verified_users, users_today: users_today}
  end
end
