require 'rails_helper'
require 'ostruct'

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
         user = User.last
         expect(Person.last.h_m_num).to eq(Person.get_number_digest(user.mobile_number))
         expect(Person.last.user_id).to eq(user.id)
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
                 push_id: "12345678", encrypt_device_id: "12345678", platform: "android", 
                 missed_call_number: "123456"}}
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
      it "verify by call is success" do
         c_param = {body: {"status" => "success", "keymatch" => "232432423", "otp_start" => "+12345"}}
         call = OpenStruct.new c_param
         User.any_instance.stub(:verify_missed_call).and_return(call)
         post :verify_missed_call, @params
         @refresh_user = User.find(@user.id)
         expect(response.status).to eql(200)
         expect(json["auth_token"]).not_to eql(@user.auth_token)
         expect(json["auth_token"]).to eql(@refresh_user.auth_token)
      end
       it "verify by call fails" do
         c_param = {body: {"status" => "error", "keymatch" => "232432423", "otp_start" => "+12345"}}
         call = OpenStruct.new c_param
         User.any_instance.stub(:verify_missed_call).and_return(call)
         post :verify_missed_call, @params
         expect(response.status).to eql(400)
      end
    end

    describe "sms serial code to a mobile number" do
      before(:each) do 
        @user = FactoryGirl.create(:user)
        @params = {user: {mobile_number: @user.mobile_number}}
      end
      it "should send serial code" do
        User.any_instance.stub(:send_sms).and_return({status: true})
        post :sms_serial_code, @params
        expect(response.status).to eql(200)
      end
      it "throws error if user no present" do
        User.any_instance.stub(:send_sms).and_return({status: true})
        post :sms_serial_code, {user: {mobile_number: "3432"}}
        expect(response.status).to eql(400)
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
    describe "contacts" do
      it "should updload user contacts" do
        @user = FactoryGirl.create(:user)
        authWithUser(@user)
        params = {hash_mobile_numbers: ["#qwerty"]}
        post :contacts, params
        expect(response.status).to eql(200)
        expect(Person.count).to eql(1)
      end
      it "should updload user contacts with names" do
        @user = FactoryGirl.create(:user)
        authWithUser(@user)
        params = {contacts: [{hash_mobile_number: "#qwerty", name: "test"}]}
        post :contacts_with_name, params
        expect(response.status).to eql(200)
        expect(Person.count).to eql(1)
        expect(Person.last.c_names.first.name).to eql("test")
      end
    end
  end
end

