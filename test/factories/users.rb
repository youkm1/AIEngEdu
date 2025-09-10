FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    phone { "010-#{rand(1000..9999)}-#{rand(1000..9999)}" }
    birth_date { Faker::Date.birthday(min_age: 20, max_age: 50) }
  end
end
