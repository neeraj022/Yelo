require 'rails_helper'

RSpec.describe Api::V1::ChatsController, :type => :controller do
  before(:each) do
    @tag = Tag.create(name: "ios", score: 2)
    @sender = FactoryGirl.create(:user)
    @receiver = User.create!(mobile_number: "9123456789")
    authWithUser(@sender)
    @params = {message: "test", sender_id: @sender.id.to_s, receiver_id: @receiver.id.to_s,
                reply_id: "", sent_time: Time.now}
  end

  describe "chat" do
    it "with a user" do
      post :send_chat, @params
      Chat.set_chat(@params)
      expect(response.status).to eql(200)
      expect(Chat.first.message).to eql(@params[:message])
      expect(@sender.chat_logs.first.chatter_id.to_s).to eql(@params[:receiver_id])
      expect(@receiver.chat_logs.first.chatter_id.to_s).to eql(@params[:sender_id])
    end
    it "is not allowed for blocked user" do
       Chat.set_chat(@params)
       post :send_chat, @params
       rec = User.find(@receiver.id.to_s)
       block = rec.chat_logs.first.build_chat_block
       block.status = 3
       block.save
       Chat.set_chat(@params)
       Chat.set_chat(@params)
       expect(response.status).to eql(200)
       expect(Chat.all.count).to eql(1)
    end
  end

end
