module MembershipJsonHelper
  extend ActiveSupport::Concern
  
  private
  
  def membership_json(membership)
    {
      id: membership.id,
      user_id: membership.user_id,
      user_name: membership.user.name,
      user_email: membership.user.email,
      membership_type: membership.membership_type,
      membership_level: Membership::LEVELS[membership.membership_type],
      available_features: membership.available_features,
      description: membership.description,
      start_date: membership.start_date,
      end_date: membership.end_date,
      price: membership.price,
      status: membership.status,
      is_active: membership.active?,
      duration_days: Membership::DURATION_DAYS[membership.membership_type],
      created_at: membership.created_at,
      updated_at: membership.updated_at
    }
  end
  
  def success_json(message:, data: nil)
    response = { success: true, message: message }
    response[:data] = data if data
    response
  end
  
  def error_json(message:, errors: nil, status: :unprocessable_entity)
    response = { success: false, message: message }
    response[:errors] = errors if errors
    response
  end
end