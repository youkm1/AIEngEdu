module MembershipTestHelpers
  def create_sample_memberships
    # Basic 활성 멤버십 (@target_user)
    @target_user.memberships.create!(
      membership_type: "basic",
      start_date: Date.current - 5.days,
      end_date: Date.current + 25.days,
      price: 49000,
      status: "active"
    )
    
    # Premium 활성 멤버십 (@regular_user)  
    @regular_user.memberships.create!(
      membership_type: "premium",
      start_date: Date.current - 10.days,
      end_date: Date.current + 50.days,
      price: 99000,
      status: "active"
    )
    
    # Basic 만료 멤버십 (@target_user)
    @target_user.memberships.create!(
      membership_type: "basic",
      start_date: Date.current - 60.days,
      end_date: Date.current - 30.days,
      price: 49000,
      status: "expired"
    )
  end
  
  def create_basic_membership(user, status: "active")
    user.memberships.create!(
      membership_type: "basic",
      start_date: Date.current,
      end_date: Date.current + 30.days,
      price: 49000,
      status: status
    )
  end
  
  def create_premium_membership(user, status: "active")
    user.memberships.create!(
      membership_type: "premium", 
      start_date: Date.current,
      end_date: Date.current + 60.days,
      price: 99000,
      status: status
    )
  end
end