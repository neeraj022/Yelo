require 'rails_helper'

RSpec.describe Api::V1::UsersController, :type => :controller do
  let(:user_attributes) {{user: {mobile_number: "+911234567890"}}}
  describe "Users API" do
     describe "creates a user" do
       it 'with valid mobile number' do
         post :create, user_attributes
         expect(response.status).to eql(200)
         expect(json["status"]).to eql("success")
         expect(User.last.mobile_number).to eq(1234567890)
         expect(User.last.country_code).to eq(91)
        end
       it 'with invalid mobile number' do
         post :create, {user: {mobile_number: "+911"}}
         expect(response.status).to eql(400)
         expect(json["status"]).to eql("error")
       end
     end
    
    describe "verify user" do
      before(:each) do
        @user = FactoryGirl.create(:user)
        @params = {user: {mobile_number: @user.mobile_number.to_s, serial_code: @user.serial_code,
                 push_id: "12345678", encrypt_device_id: "12345678", platform: "android"
                  }}
       end
      it "with valid serial code" do
         post :verify_serial_code, @params
         expect(response.status).to eql(200)
         @refresh_user = User.find(@user.id)
         expect(json["auth_token"]).not_to eql(@user.auth_token)
         expect(json["auth_token"]).to eql(@refresh_user.auth_token)
         expect(@refresh_user.serial_code).not_to eql(@user.serial_code)
      end
       it "with invalid serial code" do
         @params[:user][:serial_code] = "2323423"
         post :verify_serial_code, @params
         expect(response.status).to eql(400)
         expect(json["error_message"]).to match(/.+/)
      end
    end
    
    describe "show a user" do
      before(:each) {@user = FactoryGirl.create(:user)}
      it "with id" do
         get :show, {id: @user.id} 
         expect(response.status).to eql(200)
         expect(json["user"]["name"]).to eql(@user.name)
      end
    end
   
    describe "update user" do
      before(:each) do 
        @user = FactoryGirl.create(:user)
        authWithUser(@user)
        @params = {id: @user.id, user: {name: "yelo"}}
      end
      it "profile with id" do
         get :update, @params
         expect(response.status).to eql(200)
         expect(json["user"]["name"]).to eql("yelo")
      end
      it "interests" do
         tag = FactoryGirl.create(:tag)
         params = {user: {interest_ids: [tag.id.to_s]}}
         get :interests, params
         expect(response.status).to eql(200)
         expect(json["user"]["interest_ids"]).to eql([tag.id.to_s])
      end
    end
  end
end

