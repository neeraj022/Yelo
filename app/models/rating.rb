class Rating
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :comment,       type: String
  field :stars,        type: Integer, default: 0
  field :user_id,       type: BSON::ObjectId

  index "review_owner.user_id" => 1
  
  belongs_to  :user, index: true
  embeds_one  :review_owner
  embeds_many :rating_tags

  # validates :rating, format: {with: /[1,2,3,4,5]{0,1}/}, 
  #                    message: "the rating can be only numbers 1 to 5"
  validates :stars, inclusion: { in: [1,2,3,4,5],
    message:"can contain only numbers between 1 to 5" }, allow_blank: true, allow_nil: true
  validate :comment_or_rating_should_be_present


  def comment_or_rating_should_be_present
    if comment.blank? && stars.blank?
       errors.add(:base, "either rating or comment should be present")
    end
  end

  def save_tags(tag_ids)
    r_tag =  ""
    tag_ids.each do |id|
      tag = Tag.where(_id: id).first
      next unless tag.present?
      r_tag = self.rating_tags.create!(tag_id: tag.id, tag_name: tag.name)
    end
    self.user.save_rating_score
    return {status: true}
  rescue => e 
     e = r_tag.errors.full_messages if r_tag.errors.present?
     return {status: false, error_message: e}
  end

end
