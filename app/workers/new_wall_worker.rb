
class NewWallWorker
  include Sidekiq::Worker
  sidekiq_options queue: "new_wall", retry: false

  def perform(wall_id)
    PushRecord.save_wall(wall_id)
  end

end
