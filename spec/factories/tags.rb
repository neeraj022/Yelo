# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tag do
  	sequence(:name) { |n| "a{n}droid" }
  	score '1'
  end
end
