class ClaimStatusSerializer < CustomSerializer
  attributes :id, :amount, :status, :created_at, :updated_at

  def status
    if(object.status == 2)
      "processed"
    else
      "processing"
    end
  end
end
