# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listing do
    latitude '12.9667'
    longitude '77.5667'
    country 'india'
    city 'bangalore'
  end
end
