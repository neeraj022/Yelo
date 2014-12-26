class EmailWorker
  include Sidekiq::Worker
  sidekiq_options queue: "email", retry: false

  def perform(type, email, msg, by=nil, to=nil, tag=nil, owner=nil)
  	case type
  	when "refer"
      Mailer.refer(email, msg, by, to, tag, owner).deliver
    end
  end

end