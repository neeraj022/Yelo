class TaggedUserSerializer < CustomSerializer
  attributes :id, :user_id, :name, :details, :image_url

  def details
   if scope.present? && (scope.id.to_s == object.wall.user_id.to_s)
     {mobile_number: object.mobile_number, email: object.mobile_number}
    else
     ""
    end
  end

end
