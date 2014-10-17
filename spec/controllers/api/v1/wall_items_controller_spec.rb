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
  end
  
  describe "destroy wall item" do
    it "should delete the wall" do
      @wall_item = @wall.wall_items.create(comment: "test", user_id: @user.id)
      delete :destroy, {wall_id: @wall.id.to_s, id: @wall_item.id.to_s}
      expect(@wall.reload.wall_items.count).to eq(0)
    end
  end

end
