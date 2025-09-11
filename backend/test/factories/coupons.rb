FactoryBot.define do
  factory :coupon do
    user
    name { "AI 대화 5회 쿠폰" }
    total_uses { 5 }
    used_count { 0 }
    expires_at { 1.month.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :exhausted do
      used_count { 5 }
    end

    trait :premium do
      name { "AI 대화 10회 쿠폰" }
      total_uses { 10 }
    end

    trait :unlimited do
      name { "무제한 쿠폰" }
      total_uses { 999 }
      expires_at { 1.year.from_now }
    end
  end
end