class ServiceCardWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(card_id, type, user_id=nil)
  	case type
  	when "admin"	
      Mailer.service_card(card_id).deliver
    when "track"
      Mailer.track_service_card(card_id, user_id).deliver
    end
  end

end