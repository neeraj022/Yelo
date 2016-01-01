module GroupAttr
  extend ActiveSupport::Concern

  
  def tag_name
    @tag_name ||= Tag.where(_id: tag_id).first.name
  end

  def group_id
    @group_id ||= Group.find(self.tag.group_id).id.to_s
  end

  def group_name
    @group_name ||= Group.find(group_id).name
  end

  def group_color
    @group_color ||= Group.find(group_id).color
  end

end