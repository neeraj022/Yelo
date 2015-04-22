class ServiceCardWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(card_id)
    Mailer.service_card(card_id).deliver
  end

end