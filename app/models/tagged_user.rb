class TaggedUser
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :user_id,        type: BSON::ObjectId
  field :name,           type: String
  field :image_url,      type: String
  field :email,          type: String
  field :mobile_number,  type: String
  field :country_code,   type: Integer
  field :up_votes,       type: Integer, default: 0

  ############## relations #############################
  embedded_in :wall
  ################ validators ##########################
  validates :mobile_number, uniqueness: {message: "user can be tagged only once"}, allow_blank: true, allow_nil: true
  validates :mobile_number, presence: true,
                      numericality: true,
                      length: { is: 10 }
  validates :country_code, presence: true

  def full_mobile_number
    self.country_code.to_s + self.mobile_number.to_s
  end

end
