FactoryBot.define do
  factory :conversation do
    association :user
    title { Faker::Lorem.sentence(word_count: 3) }
  end
end
