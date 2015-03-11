class ContactWorker
  include Sidekiq::Worker
  sidekiq_options queue: "contact_address", retry: false

  def perform(c_dump_id)
    User.save_contact_dump(c_dump_id)
  end

end