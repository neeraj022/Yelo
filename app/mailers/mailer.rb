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

  def claim_mail(user)
    @name = user.name
    @mobile_number = user.mobile_number
    mail(to: "prasunjain1@gmail.com", content_type: "text/html", subject: "Yelo Claim")
  end

  def service_card(card_id)
    @card = ServiceCard.where(_id: card_id).first
    @user = @card.user
    mail(to: "prasunjain1@gmail.com", content_type: "text/html", subject: "New Service Card")
  end
end
