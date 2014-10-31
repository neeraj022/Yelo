class WallItemSerializer < CustomSerializer
  attributes :id, :user_id, :name, :image_url, :comment, :tagged_users, :tmp_id
  def tagged_users
    ActiveModel::ArraySerializer.new(object.tagged_users, scope: scope).as_json 
  end
end
