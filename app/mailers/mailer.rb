require 'digest/sha2'
class Mailer < ActionMailer::Base
  default from: 'startupnow@yelo.red'
  default "Message-ID"=>"#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@yelo.red"

  def refer(email, msg, by, to, tag, owner)
    return false unless email =~ Code.email_regex
  	 @msg = msg
  	 @referred_by = by
     @referrer = to
     @tag = tag
     @owner = owner
     mail(to: email, subject: "#{@referred_by} has recommended you for #{@tag}")
  end

  def test_mail(msg)
    mail(to: "surendarft@gmail.com", content_type: "text/html", subject: msg, body: msg)
  end
end
