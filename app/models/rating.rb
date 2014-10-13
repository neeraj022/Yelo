class Rating
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :comment,       type: String
  field :stars,         type: Integer, default: 0
  field :user_id,       type: BSON::ObjectId
  field :reviewer_id,   type: BSON::ObjectId
  field :status,        type: Boolean, default: true
  
  belongs_to  :user, index: true
  embeds_one  :rating_owner
  embeds_many :rating_tags

  validates :stars, inclusion: { in: [1,2,3,4,5],
    message:"can contain only numbers between 1 to 5" }, allow_blank: true, allow_nil: true
  validate :comment_or_rating_should_be_present
  validates :reviewer_id, uniqueness: {message: "Only one review per user"}
  validates :user_id, :reviewer_id, presence: true

  def comment_or_rating_should_be_present
    if comment.blank? && stars.blank?
       errors.add(:base, "either rating or comment should be present")
    end
  end

  def save_tags(tag_ids)
    r_tag =  ""
    user = self.user
    tags = user.tags
    tag_ids.each do |id|
      next unless tags.any?{|t| t[:id] == id.to_s}
      tag = Tag.where(_id: id).first
      r_tag = self.rating_tags.create!(tag_id: tag.id, tag_name: tag.name)
    end
    user.save_rating_and_score
    return {status: true}
  rescue => e 
     e = r_tag.errors.full_messages if r_tag.present? && r_tag.errors.present?
     return {status: false, error_message: e}
  end

end
