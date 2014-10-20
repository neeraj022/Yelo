require 'rails_helper'

RSpec.describe Api::V1::ListingsController, :type => :controller do
  let(:listing_params) {{listing: {latitude: "12.9667", longitude: "77.5667",
  	                          city:"Bangalore", country: "india"}}}
  before(:each) do 
    @user = FactoryGirl.create(:user)
    authWithUser(@user)
    @tag = FactoryGirl.create(:tag)
  end
  describe "creates a listing" do 
    it "with valid params" do 
      post :create, listing_params.merge(tag_ids: [@tag.id])
      expect(response.status).to eql(200)
      expect(json["listing"]["listing_tags"][0]["tag_id"]).to eql(@tag.id.to_s)
    end
    it "with invalid params" do 
      post :create, {listing: {latitude:0, longitude: 0}}
      expect(response.status).to eql(400)
    end
  end

  describe "with createdlistings" do
  	before(:each) do
  	  @listing = @user.listings.create(listing_params[:listing])
      @listing.create_tags([@tag.id.to_s])
    end
    it "should show listings of user" do
      get :user_listings, {id: @user.id}
      expect(response.status).to eql(200)
      expect(json["user"]["id"]).to eql(@user.id.to_s)
      expect(json["listings"].count).to eql(@user.listings.count)
      expect(json["listings"][0]["listing_tags"].count).to eql(@user.listings.first.listing_tags.count)
    end
    describe "update listing" do
       it "with valid params" do
         @tag2 = Tag.create(name: "test")
         post :update, listing_params.merge(id: @listing.id.to_s, tag_ids: [@tag.id.to_s, @tag2.id.to_s])
         expect(response.status).to eql(200)
         expect(json["listing"]["listing_tags"].count).to eql(2)
       end
    end
  end
end
