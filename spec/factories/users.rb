# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
  	sequence(:mobile_number) { |n| "9{n}373838373" }
    password '123456789'
    password_confirmation '123456789'
    description 'Test'
  end
end


