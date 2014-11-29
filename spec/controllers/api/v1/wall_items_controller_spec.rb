require 'rails_helper'

RSpec.describe Api::V1::WallItemsController, :type => :controller do
  before(:each) do
    @tag = Tag.create(name: "ios", score: 2)
    @wall_params = {wall_item: {message: "i need ios dev", latitude: "12.9667", longitude: "77.5667",
                     city:"Bangalore", country: "india", tag_id: @tag.id }}
    @user = FactoryGirl.create(:user)
    authWithUser(@user)
    @wall = @user.walls.create(@wall_params[:wall_item])
  end
  describe "create wall item" do
    it "with valid params" do
      post :create, @wall_params.merge(wall_id: @wall.id, tag_users: [{mobile_number: @user.mobile_number, name: "test"}])
      expect(response.status).to eql(200)
      @wall = Wall.find(@wall.id)
      expect(@wall.wall_items.count).to eql(1)
      expect(@wall.tagged_users.count).to eql(1)
      expect(@user.user_tags.count).to eql(1)
    end
   it "creates a new user if tagged user is not present" do
      @number = "1234567892"
      post :create, @wall_params.merge(wall_id: @wall.id, tag_users: [{mobile_number: @number.clone, name: "bob"}])
      @wall = Wall.find(@wall.id)
      @new_user = User.where(mobile_number: @number).first
      expect(response.status).to eql(200)
      expect(@wall.wall_items.count).to eql(1)
      expect(@wall.tagged_users.count).to eql(1)
      expect(@new_user.user_tags.count).to eql(1)
    end
  end
  
  describe "destroy wall item" do
    it "should delete the wall" do
      post :create, @wall_params.merge(wall_id: @wall.id, tag_users: [{mobile_number: @user.mobile_number, name: "test"}])
      @wall = @wall.reload
      @wall_item = @wall.wall_items.last
      tag_user_count = @wall.tagged_users.count
      delete :destroy, {wall_id: @wall.id.to_s, id: @wall_item.id.to_s}
      expect(@wall.reload.wall_items.count).to eq(0)
      expect(@wall.reload.wall_items.count).to eq(0)
      expect(@wall.tagged_users.count).not_to eq(tag_user_count)
    end
  end

end
