require 'rails_helper'

RSpec.describe Api::V1::ChatsController, :type => :controller do
  before(:each) do
    @tag = Tag.create(name: "ios", score: 2)
    @sender = FactoryGirl.create(:user)
    @receiver = User.create!(mobile_number: "9123456787", country_code: "91", encrypt_device_id: "12345678", mobile_verified: true)
    @params = {message: "test", sender_id: @sender.id.to_s, receiver_id: @receiver.id.to_s,
                reply_id: "", sent_time: Time.now}
  end

  describe "chat" do
  	before(:each) {authWithUser(@sender)}
    it "with a user" do
      allow(controller).to receive(:send_chat).and_return('200')
      post :send_chat, @params
      Chat.set_chat(@params)
      expect(response.status).to eql(200)
      expect(Chat.first.message).to eql(@params[:message])
      expect(@sender.chat_logs.first.chatter_id.to_s).to eql(@params[:receiver_id])
      expect(@receiver.chat_logs.first.chatter_id.to_s).to eql(@params[:sender_id])
    end
    it "is not allowed for blocked user" do
       Chat.set_chat(@params)
       allow(controller).to receive(:send_chat).and_return('200')
       post :send_chat, @params
       rec = User.find(@receiver.id.to_s)
       block = rec.chat_logs.first.build_chat_block
       block.status = ChatBlock::CONS[:BLOCK]
       block.save
       Chat.set_chat(@params)
       Chat.set_chat(@params)
       expect(response.status).to eql(200)
       expect(Chat.all.count).to eql(1)
    end
    it "is not allowed for rejected user" do
       Chat.set_chat(@params)
       allow(controller).to receive(:send_chat).and_return('200')
       post :send_chat, @params
       rec = User.find(@receiver.id.to_s)
       block = rec.chat_logs.first.build_chat_block
       block.status = ChatBlock::CONS[:BLOCK]
       block.request_time = Time.now
       block.save
       Chat.set_chat(@params)
       Chat.set_chat(@params)
       expect(response.status).to eql(200)
       expect(Chat.all.count).to eql(1)
    end
    it "records chat user for walls" do
      @wall_params = {wall: {message: "i need ios dev", latitude: "12.9667", longitude: "77.5667",
                     city:"Bangalore", country: "india", tag_id: @tag.id.to_s }}
      @wall = @sender.walls.create(@wall_params[:wall])
      allow(controller).to receive(:send_chat).and_return('200')
      post :send_chat, @params
      Chat.set_chat(@params.merge(wall_id: @wall.id.to_s))
      expect(response.status).to eql(200)
      expect(Wall.last.chat_user_ids).to eql([@sender.id.to_s])
    end
  end
  describe "chat status" do
  	before(:each) do 
      authWithUser(@sender)
     Chat.set_chat(@params)
  	end
    it "should set status of chat to block" do
      post :set_status, {chatter_id: @params[:receiver_id], type: "block"}
      usr = User.find(@sender.id.to_s)
      log = usr.chat_logs.first
      block = log.chat_block
      expect(response.status).to eql(200)
      expect(block.status).to eql(ChatBlock::CONS[:BLOCK])
      expect(log.chatter_id.to_s).to eql(@params[:receiver_id])
    end
    it "should set status of chat to reject" do
      post :set_status, {chatter_id: @params[:receiver_id], type: "reject"}
      usr = User.find(@sender.id.to_s)
      log = usr.chat_logs.first
      block = log.chat_block
      expect(response.status).to eql(200)
      expect(block.status).to eql(ChatBlock::CONS[:REJECT])
      expect(log.chatter_id.to_s).to eql(@params[:receiver_id])
    end
  end
  describe "chat seen" do 
    before(:each) do 
     Chat.set_chat(@params)
  	end
    it "should set chat status to seen" do
      authWithUser(@receiver)
      post :set_seen, {created_at: Chat.last.created_at}
      expect(response.status).to eql(200)
      expect(Chat.last.is_seen).to eql(true)
    end
  end
  describe "user chats" do 
    before(:each) do 
     Chat.set_chat(@params)
    end
    it "should set get users chat history" do
      authWithUser(@receiver)
      get :user_chats 
      expect(response.status).to eql(200)
      expect(json["chats"].count).to eql(1)
    end
  end
end
