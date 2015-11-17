class ContactWallWorker
  include Sidekiq::Worker
  sidekiq_options queue: "contact_wall", retry: false

  def perform(wall_id)
    PushRecord.save_contact_wall(wall_id)
  end

end
