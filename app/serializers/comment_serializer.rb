class CommentSerializer < CustomSerializer
  attributes :id, :message, :status, :spam_count, :created_at, :updated_at, :user_details
end
