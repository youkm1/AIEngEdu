FactoryBot.define do
  factory :message do
    association :conversation
    role { "user" }
    content { Faker::Lorem.paragraph }

    trait :user_message do
      role { "user" }
    end

    trait :assistant_message do
      role { "assistant" }
    end

    trait :system_message do
      role { "system" }
    end
  end
end
