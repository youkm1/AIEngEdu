# 개발 환경에서만 데이터 정리
if Rails.env.development?
  puts "Cleaning database..."
  Membership.destroy_all
  User.destroy_all
end

# Users 생성
puts "Creating users..."
users = []

10.times do |i|
  user = User.find_or_create_by(email: "user#{i+1}@example.com") do |u|
    u.name = "User #{i+1}"
    u.phone = "010-#{rand(1000..9999)}-#{rand(1000..9999)}"
    u.birth_date = Date.today - rand(20..50).years
  end
  users << user
end

# 특정 테스트 유저
admin = User.create!(
  email: "admin@ringle.com",
  name: "Admin User",
  phone: "010-1234-5678",
  birth_date: Date.new(1990, 1, 1)
)

# Memberships 생성
puts "Creating memberships..."

# 각 유저에게 멤버십 부여
users.each_with_index do |user, index|
  # 50% 유저는 premium, 50%는 basic
  membership_type = index.even? ? "premium" : "basic"
  
  # 활성 멤버십
  Membership.create!(
    user: user,
    membership_type: membership_type,
    start_date: Date.today - rand(1..30).days,
    end_date: Date.today + rand(30..365).days,
    price: membership_type == "premium" ? 99000 : 49000,
    status: "active"
  )
  
  # 일부 유저에게 과거 멤버십 기록 추가
  if index < 5
    Membership.create!(
      user: user,
      membership_type: "basic",
      start_date: Date.today - 400.days,
      end_date: Date.today - 35.days,
      price: 49000,
      status: "expired"
    )
  end
end

# Admin은 premium 멤버십
Membership.create!(
  user: admin,
  membership_type: "premium",
  start_date: Date.today,
  end_date: Date.today + 1.year,
  price: 99000,
  status: "active"
)

puts "Seed completed!"
puts "Created #{User.count} users"
puts "Created #{Membership.count} memberships"
puts "  - Active: #{Membership.where(status: 'active').count}"
puts "  - Premium: #{Membership.premium.count}"
puts "  - Basic: #{Membership.basic.count}"