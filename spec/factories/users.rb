# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
  	# sequence(:mobile_number) { |n| "988373838373" }
  	mobile_number '1234567890'
    description 'Test'
    sms_verify 'true'
    push_id '123213234'
    encrypt_device_id '324rm32n4kj'
    platform 'device_id'
    name 'test'
    country_code '91'
    latitude '12.123'
    longitude '13.14'
    country 'india'
    city 'bangalore'
  end
end


