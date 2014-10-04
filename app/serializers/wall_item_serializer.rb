class WallItemSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :name, :image_url, :comment, :tagged_users
  def tagged_users
    ActiveModel::ArraySerializer.new(object.tagged_users, scope: scope).as_json 
  end
end
