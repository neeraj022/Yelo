require 'spec_helper'

describe "Users API", :type => :api do
  
  it 'creates a user' do
    params = {user: {mobile_number: "+911234567890"}}
    post "/api/v1/users", params
    expect(response).to be_success
    json["status"].should eql("success")
    User.last.mobile_number.should eq(1234567890)
    User.last.country.should eq(91)
   end

end


