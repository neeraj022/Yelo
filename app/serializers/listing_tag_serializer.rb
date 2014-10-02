class ListingTagSerializer < CustomSerializer
  attributes :id, :tag_name, :tag_id

  def tag_id
  	object.id.to_s
  end

end
