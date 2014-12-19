require 'digest/sha2'
class Mailer < ActionMailer::Base
  default from: 'startupnow@yelo.red'
  default "Message-ID"=>"#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@yelo.red"

  def refer(email, msg, referred_by)
    return false unless email =~ Code.email_regex
  	 @msg = msg
  	 @referred_by = referred_by
     mail(to: email, subject: "#{@referred_by} referred you on yelo")
  end
end
