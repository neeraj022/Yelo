class ClaimStatusSerializer < CustomSerializer
  attributes :id, :amount, :status, :created_at, :updated_at
end
