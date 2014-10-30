require 'rails_helper'

RSpec.describe Api::V1::SearchController, :type => :controller do

  describe "wall search" do
    before(:each) do 
      Wall.__elasticsearch__.create_index! force: true
      @tag_ios = Tag.create(name: "ios", score: 2)
      @tag_ruby = Tag.create(name: "ruby", score: 2)
      @user1 = FactoryGirl.create(:user)
      @user2 = User.create!(mobile_number: "9123456789", encrypt_device_id: "12345678", mobile_verified: true)
      @user3 = User.create!(mobile_number: "4873456789", encrypt_device_id: "1452345678", mobile_verified: true)
      @wall_params1 = {wall: {message: "i need ios dev", tag_id: @tag_ios.id.to_s }}
      @wall_params2 = {wall: {message: "i need ruby dev", tag_id: @tag_ruby.id.to_s }}
      @bangalore = {latitude: "12.9667", longitude: "77.5667",city:"Bangalore", country: "india"}
      @mysore = {latitude: "12.3000", longitude: "76.6500",city:"mysore", country: "india"}
      @delhi = {latitude: "28.6139", longitude: "77.2089", city:"delhi", country: "india"}
      @wall_bangalore = @user1.walls.create(@wall_params1[:wall].merge(@bangalore))
      @wall_mysore = @user2.walls.create(@wall_params2[:wall].merge(@mysore))
      @wall_delhi = @user3.walls.create(@wall_params2[:wall].merge(@delhi))
      sleep 1
    end
    it "should all walls with no params" do
      get :search, {type: "wall"}
      expect(response.status).to eql(200)
      expect(json["search"].count).to eql(3)
    end
    it "should give walls of particular radius" do
       get :search, {type: "wall", latitude: "12.9667", longitude: "77.5667", radius: 200}
       expect(response.status).to eql(200)
       expect(json["search"].count).to eql(2)
    end
    it "should give walls of particular radius or a particular city" do
       get :search, {type: "wall", or_city: "delhi", or_country: "india", latitude: "12.9667", longitude: "77.5667", radius: 200}
       expect(response.status).to eql(200)
       expect(json["search"].count).to eql(3)
    end
    it "should give walls of particular radius and tag ids" do
       get :search, {type: "wall", tag_ids: [@tag_ios.id.to_s] ,latitude: "12.9667", longitude: "77.5667", radius: 200}
       expect(response.status).to eql(200)
       expect(json["search"].count).to eql(1)
    end
    it "should give walls of particular radius or city and tag ids " do
       get :search, {type: "wall", or_city: "delhi", or_country: "india", tag_ids: [@tag_ruby.id.to_s] ,
       	latitude: "12.3000", longitude: "77.2089", radius: 200}
       expect(response.status).to eql(200)
       expect(json["search"].count).to eql(2)
    end
     it "should give walls of a city" do
       get :search, {type: "wall", city: "bangalore", country: "india"}
       expect(response.status).to eql(200)
       expect(json["search"].count).to eql(1)
    end
     it "should give walls of a tag" do
       get :search, {type: "wall", tag_ids: [@tag_ruby.id.to_s]}
       expect(response.status).to eql(200)
       expect(json["search"].count).to eql(2)
    end
  end

end
