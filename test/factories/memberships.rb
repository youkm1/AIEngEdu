FactoryBot.define do
  factory :membership do
    association :user
    membership_type { %w[basic premium].sample }
    start_date { Date.today }
    end_date { Date.today + 30.days }
    price { membership_type == "premium" ? 99000 : 49000 }
    status { "active" }

    trait :premium do
      membership_type { "premium" }
      price { 99000 }
      end_date { Date.today + 60.days }
    end

    trait :basic do
      membership_type { "basic" }
      price { 49000 }
      end_date { Date.today + 30.days }
    end

    trait :expired do
      start_date { Date.today - 60.days }
      end_date { Date.today - 1.day }
      status { "expired" }
    end
  end
end