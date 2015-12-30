module GroupAttr
  extend ActiveSupport::Concern

  
  def tag_name
    puts "tag id is #{tag_id}"
    @tag_name ||= Tag.where(:_id.in => tag_id.to_s.split(',')).map{|n|n.name}
  end

  def group_id
    if self.tag_id.to_s.include?(',')
      @group_id ||= Tag.where(:_id.in => self.tag_id.to_s.split(',')).map{|n|n.group_id.to_s}
    else
      @group_id ||= Tag.where(:_id => self.tag_id.to_s).map{|n|n.group_id.to_s}
    end
    # @group_id ||= Group.find(self.tag.group_id).id.to_s
    # @group_id ||= Tag.where(:_id.in => self.tag_id.to_s.include?(',') ? self.tag_id.to_s.split(',') : self.tag_id.to_s).map{|n|n.group_id.to_s}
  end

  def group_name
    @group_name ||= Group.where(:_id.in => group_id).map{|n|n.name}
  end

  def group_color
    @group_color ||= Group.where(:_id.in => group_id).map{|n|n.color}
  end

end