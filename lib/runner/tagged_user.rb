Wall.all.each do |w|
  tg_users = w.tagged_users
  tg_users.each do |t|
    if(t.user_id.blank?)
    	t.is_present = false
    else
       user = User.where(_id: t.user_id).first
       if(user.present? && user.mobile_verified)
         t.is_present = true
       else
       	t.is_present = false
       end
    end
    t.save
  end
end