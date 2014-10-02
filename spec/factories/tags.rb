# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tag do
  	sequence(:name) { |n| "a{n}droid" }
  	name 'android'
  	score '1'
  end
end
