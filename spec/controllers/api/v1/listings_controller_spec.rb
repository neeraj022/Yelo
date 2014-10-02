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
end
