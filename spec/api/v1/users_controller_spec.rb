require 'spec_helper'

describe "Users API", :type => :api do
  describe "creating user"
    it 'with valid mobile number' do
      params = {user: {mobile_number: "+911234567890"}}
      post "/api/v1/users", params
      expect(response).to be_success
      json["status"].should eql("success")
      User.last.mobile_number.should eq(1234567890)
      User.last.country.should eq(91)
    end

    it 'with invalid mobile number' do
      params = {user: {mobile_number: "+9112345"}}
      post "/api/v1/users", params
      expect(response).to be_success
      json["status"].should eql("error")
    end
  end
end


