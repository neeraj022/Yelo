class ClaimWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id)
  	user = User.where(_id: user_id).first
  	num = Rails.application.secrets.w_mobile_number
  	puts user_id
  	puts num
    num = User.mobile_number_format(num) 
    yelo = User.where(mobile_number: num[:mobile_number]).first
    msg = "Your claim has been processed. you will hear from us in a week"
    puts "#{yelo.id.to_s}"
    puts "#{user.id.to_s}"
    User.send_chat_message(yelo, user, msg)
    Mailer.claim_mail(user).deliver
  end

end