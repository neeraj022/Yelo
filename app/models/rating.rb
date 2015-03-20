class Rating
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Common

  field :comment,           type: String
  field :stars,             type: Integer, default: 0
  field :user_id,           type: BSON::ObjectId
  field :reviewer_id,       type: BSON::ObjectId
  field :service_card_id,   type: BSON::ObjectId
  field :status,            type: Integer, default: 1
  
  belongs_to  :user, index: true
  belongs_to  :service_card
  
  validates :stars, inclusion: { in: [1,2,3,4,5],
    message:"can contain only numbers between 1 to 5" }, allow_blank: true, allow_nil: true
  validate :comment_or_rating_should_be_present
  validates :user_id, :reviewer_id, presence: true
  validates_uniqueness_of :reviewer_id, :scope => :service_card_id

  def comment_or_rating_should_be_present
    if comment.blank? && stars.blank?
       errors.add(:base, "either rating or comment should be present")
    end
  end

end
