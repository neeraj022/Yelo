require 'rails_helper'

RSpec.describe Api::V1::UsersController, :type => :controller do
  describe "Users API" do
    it 'creates a user' do
      params = {user: {mobile_number: "+911234567891"}}
      post :create, params
      expect(response.status).to eql(200)
      expect(json["status"]).to eql("success")
      expect(User.last.mobile_number).to eq(1234567891)
      expect(User.last.country_code).to eq(91)
     end
  end
end

