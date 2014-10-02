require 'rails_helper'

RSpec.describe Api::V1::TagsController, :type => :controller do
  let(:listing_params) {{latitude: "12.9667", longitude: "77.5667",
  	                          city:"Bangalore", country: "india"}}
  before(:each) do
    @tag1 = Tag.create(name: "android", score: 1)
    @tag2 = Tag.create(name: "ios", score: 2)
    @user = FactoryGirl.create(:user)
  end
  describe "tag suggestion" do
  	before(:each) do 
      @listing = @user.listings.create(listing_params)
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
  end
end
