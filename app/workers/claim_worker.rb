class ClaimWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id)
  	user = User.where(_id: user_id).first
    Mailer.claim_mail(user).deliver
  end

end