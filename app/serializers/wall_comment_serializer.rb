class WallCommentSerializer < CustomSerializer
  attributes :id, :message, :chat_users_count, :tagged_users_count, :created_at,
             :tag_name, :country, :city, :state, :address, :status, :tmp_id, :tag_id, :group_id,
             :keywords, :group_name, :wall_chats, :group_color, :updated_at, :comments, :comments_count
  has_one  :wall_image
  has_one  :wall_owner
  
  def comments
  	object.allowed_comments
  end
end

