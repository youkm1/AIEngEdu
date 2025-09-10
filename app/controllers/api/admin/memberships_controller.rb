class Api::Admin::MembershipsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_admin
  
  # POST /api/admin/memberships/assign
  # 어드민이 유저에게 멤버십을 부여하고 삭제할 수 있습니다
  def assign
    user = User.find(params[:user_id])
    
    # 기존 활성 멤버십 만료 처리
    user.memberships.active.update_all(status: 'expired')
    
    # 새 멤버십 생성
    membership = user.memberships.build(
      membership_type: params[:membership_type],
      start_date: params[:start_date] || Date.current,
      price: params[:price] || 0,
      status: 'active'
    )
    
    # 자동으로 종료일 설정
    duration = Membership::DURATION_DAYS[membership.membership_type] || 30
    membership.end_date = membership.start_date + duration.days
    
    if membership.save
      render json: {
        message: "멤버십이 성공적으로 부여되었습니다",
        membership: membership_json(membership)
      }, status: :created
    else
      render json: { errors: membership.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/admin/memberships/:id
  # 멤버십 삭제
  def destroy
    membership = Membership.find(params[:id])
    user = membership.user
    
    membership.destroy
    
    render json: {
      message: "멤버십이 삭제되었습니다",
      user_id: user.id,
      user_name: user.name
    }
  end
  
  # GET /api/admin/memberships
  # 모든 멤버십 조회
  def index
    memberships = Membership.includes(:user)
    memberships = memberships.where(status: params[:status]) if params[:status].present?
    memberships = memberships.where(membership_type: params[:type]) if params[:type].present?
    
    render json: memberships.map { |m| membership_json(m) }
  end
  
  private
  
  def require_admin
    # 실제 프로덕션에서는 적절한 인증/인가 로직 필요
    # 현재는 admin@ringle.com 이메일로 간단히 체크
    unless current_user&.email == 'admin@ringle.com'
      render json: { error: "관리자 권한이 필요합니다" }, status: :forbidden
    end
  end
  
  def current_user
    @current_user ||= User.find_by(id: params[:admin_user_id] || request.headers['X-Admin-User-Id'])
  end
  
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
      created_at: membership.created_at,
      updated_at: membership.updated_at
    }
  end
end