# 환경별 데이터 관리
case Rails.env
when 'development', 'test'
  puts "Cleaning #{Rails.env} database..."
  Membership.destroy_all
  User.destroy_all
when 'production'
  # 프로덕션에서는 기존 데이터 유지하고 없는 것만 추가
  puts "Production environment - only adding missing data..."
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

# 각 유저에게 하나의 멤버십만 부여
users.each_with_index do |user, index|
  # 50% 유저는 premium, 50%는 basic
  membership_type = index.even? ? "premium" : "basic"

  # 멤버십 기간 자동 계산
  duration_days = membership_type == "premium" ? 60 : 30
  start_date = Date.today - rand(1..30).days

  # 활성 멤버십 (사용자당 하나만)
  Membership.create!(
    user: user,
    membership_type: membership_type,
    start_date: start_date,
    end_date: start_date + duration_days.days,
    price: membership_type == "premium" ? 99000 : 49000,
    status: "active"
  )
end

# Admin은 premium 멤버십 (학습, 대화, 분석 모두 사용 가능)
start_date = Date.today
Membership.create!(
  user: admin,
  membership_type: "premium",
  start_date: start_date,
  end_date: start_date + 60.days,
  price: 99000,
  status: "active"
)

puts "Seed completed!"
puts "Created #{User.count} users"
puts "Created #{Membership.count} memberships"
puts "  - Active: #{Membership.where(status: 'active').count}"
puts "  - Premium (학습/대화/분석 가능): #{Membership.premium.count}"
puts "  - Basic (학습만 가능): #{Membership.basic.count}"
