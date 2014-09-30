require 'spec_helper'

describe "Users API", :type => :api do

  # before(:each) do
  #   @user = FactoryGirl.create(:user)  
  #   @authorization = ActionController::HttpAuthentication::Token.encode_credentials(@user.auth_token ,{:email => @user.email})
  # end
  let(:user_attributes) { {first_name:"test", provider: "manual", email:"test123@test.com", password:"123456789"} }
  
  it 'creates a user' do
    params =  user_attributes 
    post "/api/v1/create_user", params
    expect(response).to be_success
    json["email"].should eql("test123@test.com")
  end

  it 'shows the current logged in user' do
    @user = FactoryGirl.create(:user)
    @authorization = ActionController::HttpAuthentication::Token.encode_credentials(@user.auth_token ,{:email => @user.email})
    get "/api/v1/users", {}, authorization: @authorization
    expect(response).to be_success
    expect(json["id"]["$oid"]).to eq(@user.id.to_s) 
  end

  it 'shows the user profile' do
    @user = FactoryGirl.create(:user)
    get "/api/v1/user_profile", {id: @user.id.to_s}
    expect(response).to be_success
    expect(json["id"]["$oid"]).to eq(@user.id.to_s) 
  end

  it 'updates the user' do
    @user = FactoryGirl.create(:user)
    @authorization = ActionController::HttpAuthentication::Token.encode_credentials(@user.auth_token ,{:email => @user.email})
    put "/api/v1/users", {user: {first_name: "updated"}}, authorization: @authorization
    expect(response).to be_success
    expect(json["first_name"]).to eq("updated") 
  end

  it 'delete a user' do
    @user = FactoryGirl.create(:user)
    @authorization = ActionController::HttpAuthentication::Token.encode_credentials(@user.auth_token ,{:email => @user.email})
    expect {
      delete "/api/v1/users", {id: @user.id.to_s}, :authorization => @authorization  
     }.to change(User, :count).by(-1)
     expect(response).to be_success
  end

  it 'creates a password reset token' do
    @user = FactoryGirl.create(:user)
    get "/api/v1/password_reset", {email: @user.email}
    expect(response).to be_success
    User.last.reset_password_token.should be_a_kind_of(String)
  end

  it 'changes the password by reset password token' do
    @user = FactoryGirl.create(:user) 
    @user.reset_password_token = "123456789"
    @user.reset_password_sent_at = Time.zone.now
    @user.save
    post "/api/v1/password_reset", {token: "123456789", email: @user.email, password: "password" }
    expect(response).to be_success
    User.last.encrypted_password.should_not eq(@user.encrypted_password)
  end

  it 'reset password token expires in 20 minutes' do
    @user = FactoryGirl.create(:user) 
    @user.reset_password_token = "123456789"
    @user.reset_password_sent_at = Time.zone.now - 20*60   
    @user.save
    post "/api/v1/password_reset", {token: "123456789", email: @user.email, password: "password" }
    expect(response.status).to eq(400)
    User.last.encrypted_password.should eq(@user.encrypted_password)
  end

end