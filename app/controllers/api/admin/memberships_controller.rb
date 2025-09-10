class Api::Admin::MembershipsController < ApplicationController
  include MembershipJsonHelper
  include ErrorHandler
  
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
      render json: success_json(
        message: "멤버십이 성공적으로 부여되었습니다",
        data: membership_json(membership)
      ), status: :created
    else
      render json: error_json(
        message: "멤버십 부여에 실패했습니다",
        errors: membership.errors.full_messages
      ), status: :unprocessable_entity
    end
  end
  
  # DELETE /api/admin/memberships/:id
  # 멤버십 삭제
  def destroy
    membership = Membership.find(params[:id])
    user = membership.user
    
    membership.destroy
    
    render json: success_json(
      message: "멤버십이 삭제되었습니다",
      data: { user_id: user.id, user_name: user.name }
    )
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
    admin_user_id = params[:admin_user_id] 
    admin_user = User.find_by(id: admin_user_id)
    
    unless admin_user&.email == 'admin@ringle.com'
      render json: error_json(
        message: "관리자 권한이 필요합니다"
      ), status: :forbidden
    end
  end
  
  # membership_json 메서드는 MembershipJsonHelper에서 제공
end
