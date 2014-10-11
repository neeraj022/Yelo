class CustomSerializer < ActiveModel::Serializer
  def id
    object.id.to_s
  end
  def user_id
    object.user_id.to_s
  end
  def tag_id
    object.tag_id.to_s
  end
end