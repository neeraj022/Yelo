require 'rails_helper'

RSpec.describe Api::V1::TagsController, :type => :controller do
  let(:listing_params) {{listing: {latitude: "12.9667", longitude: "77.5667",
  	                          city:"Bangalore", country: "india"}}}
  before(:each) do
    @tag1 = Tag.create(name: "android", score: 1)
    @tag2 = Tag.create(name: "ios", score: 2)
    @user = FactoryGirl.create(:user)
  end
  describe "tag" do
  	before(:each) do 
      @listing = @user.listings.create(listing_params[:listing])
      @listing.create_tags([@tag1.id.to_s])
    end
  	 it "should give top tags" do
         get :suggestions
         expect(response.status).to eql(200)
         expect(json["tags"].count).to eql(2)
  	 end
  	 it "should give top tags without usertags and user tags seperately" do
       authWithUser(@user)
       get :suggestions
       expect(response.status).to eql(200)
       expect(json["tags"].count).to eql(1)
       expect(json["user_tags"].count).to eql(1)
  	 end
  	 it "should give auto complete suggestions" do
        get :auto_suggestions, {q:"i"}
        expect(response.status).to eql(200)
        expect(json["tags"][0]["name"]).to eql("ios")
  	 end
     it "should give all tags of auser" do
        get :all_user_tags, {user_id: @user.id.to_s}
        expect(response.status).to eql(200)
        expect(json["user"]).to eq(@user.all_tags.deep_stringify_keys)
     end
  end
end
