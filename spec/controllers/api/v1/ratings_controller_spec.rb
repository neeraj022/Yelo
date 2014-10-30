require 'rails_helper'

RSpec.describe Api::V1::RatingsController, :type => :controller do
  before(:each) do
    @tag = Tag.create(name: "ios", score: 2)
    @user1 = FactoryGirl.create(:user)
    @user2 = User.create!(mobile_number: "8934567890", encrypt_device_id: "12345678", mobile_verified: true)
    @listing = FactoryGirl.create(:listing)
    @listing.update_attributes(user_id: @user1.id)
    @listing.create_tags([@tag.id.to_s])
    @params = {rating: {comment: "test", stars: "3", user_id: @user1.id.to_s}, tag_ids: [@tag.id.to_s]}
    authWithUser(@user2)
  end

  describe "create rating" do
  	it "with valid params" do
  	  post :create, @params
  	  expect(response.status).to eql(200)
  	  expect(@user1.ratings.count).to eql(1)
  	  expect(@user1.reload.statistic.rating_avg).to eql(3)
    end
    it "with invalid params" do
  	  post :create, {user_id: @user1.id.to_s}
  	  expect(response.status).to eql(400)
    end
    it "only one rating per user" do
      @user1.ratings.create(stars: "3", reviewer_id: @user2.id, user_id: @user1.id.to_s)
  	  post :create, @params
  	  expect(response.status).to eql(400)
    end
  end

  describe "update rating" do
  	before(:each){@rating = @user1.ratings.create(stars: "3", reviewer_id: @user2.id, user_id: @user1.id.to_s) }
    it "with valid params" do
      put :update, {rating: {comment: "update"}, tag_ids:[@tag.id.to_s], id: @rating.id.to_s}
      expect(response.status).to eql(200)
      expect(json["rating"]["comment"]).to eql("update")
      expect(@rating.reload.rating_tags.count).to eql(1)
    end
  end

  describe "destroy rating" do
    before(:each){@rating = @user1.ratings.create(stars: "3", reviewer_id: @user2.id, user_id: @user1.id.to_s) }
    it "delete the rating" do
      delete :destroy, {id: @rating.id.to_s}
      expect(response.status).to eql(200)
      expect(@user1.ratings.count).to eql(0)
    end
  end 
end
