class CommentSerializer < CustomSerializer
  attributes :id, :message, :status, :spam_count
end
