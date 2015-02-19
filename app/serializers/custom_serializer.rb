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

  def created_at
    object.created_at.to_s
  end

  def updated_at
    object.updated_at.to_s
  end

  def word_id
    object.word_id.to_s
  end

  def group_id
    object.group_id.to_s
  end
end