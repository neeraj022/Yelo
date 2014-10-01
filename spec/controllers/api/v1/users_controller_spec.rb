require 'rails_helper'

RSpec.describe Api::V1::UsersController, :type => :controller do
  let(:user_attributes) {{mobile_number: "1234567890", country_code: "91"}}
  describe "Users API" do
     describe "creates a user" do
       it 'with valid mobile number' do
         params = {user: {mobile_number: "+911234567891"}}
         post :create, params
         expect(response.status).to eql(200)
         expect(json["status"]).to eql("success")
         expect(User.last.mobile_number).to eq(1234567891)
         expect(User.last.country_code).to eq(91)
        end
       it 'with invalid mobile number' do
         params = {user: {mobile_number: "+911"}}
         post :create, params
         expect(response.status).to eql(400)
         expect(json["status"]).to eql("error")
       end
     end
    
    describe "verify user" do
      before(:each) do
        @user = User.create(user_attributes)
        @params = {user: {mobile_number: "91"+@user.mobile_number.to_s, serial_code: @user.serial_code,
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
      it "with providing id" do
         get :update, @params
         expect(response.status).to eql(200)
         expect(json["user"]["name"]).to eql("yelo")
      end
    end
  
  end
end

