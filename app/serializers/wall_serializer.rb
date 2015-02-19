class WallSerializer < CustomSerializer
  attributes :id, :message, :chat_users_count, :tagged_users_count, :created_at,
             :tag_name, :country, :city, :state, :address, :status, :tmp_id, :tag_id, :group_id,
             :keywords, :group_name, :wall_chats, :group_color, :updated_at
  has_one  :wall_image
  has_one  :wall_owner
  has_many :wall_items

end
