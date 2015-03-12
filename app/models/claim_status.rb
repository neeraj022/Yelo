class ClaimStatus
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :number, type: String
  field :amount, type: Integer
  field :status, type: Integer, default: 1
  field :n_sent, type: Boolean, default: false

  belongs_to :user

  before_update :notify_user

  def notify_user
    return if (self.n_sent)
    return if (self.status != 2)
    user = self.user
    msg = "Your claim of Rs #{self.amount} has been processed. For any query contact startupnow@yelo.red"
    Code.send_sms(user.full_mobile_number, msg)
    self.n_sent = true
  end
end
