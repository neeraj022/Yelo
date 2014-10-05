require 'rails_helper'

RSpec.describe Api::V1::WallsController, :type => :controller do
  let(:wall_params){{wall: {message: "i need ios dev", latitude: "12.9667", longitude: "77.5667",
                     city:"Bangalore", country: "india", tag_id: "6578798" }}}
  before(:each) do
    @tag = Tag.create(name: "ios", score: 2)
    @user = FactoryGirl.create(:user)
    authWithUser(@user)
  end
  describe "create wall" do
    it "with valid params" do
      post :create, wall_params
      expect(response.status).to eql(200)
      expect(json["wall"]["message"]).to eql(wall_params[:wall][:message])
    end
    it "with invalid params" do
      post :create, {latitude: "0", longitude: "0"}
      expect(response.status).to eql(400)
    end
    it "not allowed for specified time" do
      @user.walls.create(wall_params[:wall])
      post :create, wall_params
      expect(response.status).to eql(400)
      expect(json["error_message"][0]).to match(/only/)
    end
  end
  describe "with a created wall" do
    before(:each) do
      @wall = @user.walls.create(wall_params[:wall])
    end
    describe "update wall" do
      it "with valid params" do
        put :update, {id: @wall.id, wall: {message: "now android"}}
        expect(response.status).to eql(200)
        expect(json["wall"]["message"]).to eql("now android")
      end
      it "with invalid params" do
        Wall.any_instance.stub(:save).and_return(false)
        put :update, {id: @wall.id, wall: {latitude: "0", longitude: "0"}}
        expect(response.status).to eql(400)
      end
    end
  end
end
