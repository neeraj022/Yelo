class ListingKeywordSerializer < CustomSerializer
  attributes :id, :name, :word_id, :keyword_id

  def word_id
  	object.word_id.to_s
  end

  def keyword_id
  	object.keyword_id.to_s
  end


end


