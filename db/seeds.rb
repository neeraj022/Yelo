# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
num = Rails.application.secrets.w_mobile_number
num = User.mobile_number_format(num)
w_user = User.where(mobile_number: num[:mobile_number]).first_or_initialize
w_user.country_code = num[:country_code]
w_user.save

JSON.parse(open("#{Rails.root}/db/tags.json").read).each do |s|
  group = Group.where(name: s.keys.first.downcase).first_or_create
  s[s.keys.first].each do |t|
    # puts "#{s.keys.first}#{t}"
    group.tags.where(name: t.downcase).first_or_create
  end
end

setting = AppSetting.first
AppSetting.create unless setting.present?

num = Rails.application.secrets.admin_mobile
num = User.mobile_number_format(num)
a_email = Rails.application.secrets.admin_email
admin_user = User.where(mobile_number: num[:mobile_number]).first
if(admin_user.blank?)
  admin_user  = User.new(push_id: "xxxxx", encrypt_device_id: "xxxxxxx", platform: "none")
  admin_user.mobile_number = num[:mobile_number]
  admin_user.country_code = num[:country_code]
  admin_user.name = "admin"
  admin_user.description = "admin"
end
admin_user.email = a_email
admin_user.password = Rails.application.secrets.admin_password
admin_user.is_admin = true
admin_user.save


# JSON.parse(open("#{Rails.root}/db/sub_categories.json").read).each do |s|
#   t = Tag.where(name: s["name"], _id: s["_id"]["$oid"]).first_or_create 
# end


# JSON.parse(open("#{Rails.root}/db/users.json").read).each do |s|
#   num = User.mobile_number_format(s["mobile_number"])
#   mobile = num[:mobile_number]
#   country_code = num[:country_code]
#   user = User.where(mobile_number: mobile).first
#   if(user.blank?)
#   	user = User.new
#   	user.id = s["_id"]["$oid"]
#   	user.mobile_number = mobile
#     user.name = s["name"]
#     user.description = s["description"]
#     user.country_code = country_code
#     user.save
#   end
# end


# JSON.parse(open("#{Rails.root}/db/listings.json").read).each do |s|
#   list = Listing.where(user_id: s["_id"]["$oid"]).first
#   if(list.blank?)
# 	  list = Listing.new
# 	  list.user_id = s["_id"]["$oid"]
# 	  list.latitude = s["latitude"]
# 	  list.longitude = s["longitude"]
# 	  list.country = s["country"]
# 	  list.city = s["city"]
# 	  list.country = s["counrty"]
# 	  list.save
# 	end
# 	list.create_tags(s["sub_cat_ids"])
# end







