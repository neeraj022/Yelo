require 'rails_helper'

RSpec.describe Api::V1::WallsController, :type => :controller do
  
  before(:each) do
    Wall.__elasticsearch__.create_index! force: true
    Listing.__elasticsearch__.create_index! force: true
    @tag = Tag.create(name: "ios", score: 2)
    @user = FactoryGirl.create(:user)
    authWithUser(@user)
    @params = {wall: {message: "i need ios dev", latitude: "12.9667", longitude: "77.5667",
                     city:"Bangalore", country: "india", tag_id: @tag.id.to_s }}
    sleep 1
  end
 
  describe "create wall" do
    it "with valid params" do
      post :create, @params
      expect(response.status).to eql(200)
      expect(json["wall"]["message"]).to eql(@params[:wall][:message])
    end
    it "with invalid params" do
      post :create, {latitude: "0", longitude: "0"}
      expect(response.status).to eql(400)
    end
    it "not allowed for specified time" do
      @user.walls.create(@params[:wall])
      post :create, @params
      expect(response.status).to eql(400)
      expect(json["error_message"][0]).to match(/only/)
    end
  end
 
  describe "with a created wall" do
    before(:each) do
      @wall = @user.walls.create(@params[:wall])
    end
    it "get connects of wall" do
      get :connects, {id: @wall.id}
      expect(response.status).to eql(200)
      expect(json["tag_users"]).to eql([])
      expect(json["chat_users"]).to eql([])
    end
    it "it should close the wall with optional solver" do
      get :wall_close, {id: @wall.id, is_solved: true}
      expect(response.status).to eql(200)
      expect(json["status"]).to eql("success")
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
     
     it "should show walls of logged in user" do
       get :user_walls, {user_id: @user.id.to_s}
       expect(response.status).to eql(200)
       expect(json.count).to eql(@user.walls.count)
     end
      
      it "should delete the wall" do
        expect do
          delete :destroy, {id: @wall.id.to_s}
        end.to change(Wall, :count).by(-1)
      end
    end

end


