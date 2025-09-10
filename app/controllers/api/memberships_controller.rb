class Api::MembershipsController < ApplicationController
  include MembershipJsonHelper
  include ErrorHandler
  
  skip_before_action :verify_authenticity_token
  before_action :set_user, only: [:create, :index]
  before_action :set_membership, only: [:show, :update, :destroy]
  
  # GET /api/users/:user_id/memberships
  def index
    @memberships = @user.memberships.includes(:user)
    render json: @memberships.map { |m| membership_json(m) }
  end
  
  # GET /api/memberships/:id
  def show
    render json: membership_json(@membership)
  end
  
  # POST /api/users/:user_id/memberships
  def create
    # 기존 활성 멤버십 비활성화
    @user.memberships.active.update_all(status: 'expired')
    
    @membership = @user.memberships.build(membership_params)
    @membership.status = 'active'
    
    # 자동으로 종료일 설정 (멤버십 타입에 따라)
    if @membership.start_date.present? && @membership.membership_type.present?
      duration = Membership::DURATION_DAYS[@membership.membership_type] || 30
      @membership.end_date = @membership.start_date + duration.days
    end
    
    if @membership.save
      render json: success_json(
        message: "멤버십이 성공적으로 생성되었습니다",
        data: membership_json(@membership)
      ), status: :created
    else
      render json: error_json(
        message: "멤버십 생성에 실패했습니다",
        errors: @membership.errors.full_messages
      ), status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/memberships/:id
  def update
    if @membership.update(membership_params)
      render json: success_json(
        message: "멤버십이 성공적으로 업데이트되었습니다",
        data: membership_json(@membership)
      )
    else
      render json: error_json(
        message: "멤버십 업데이트에 실패했습니다",
        errors: @membership.errors.full_messages
      ), status: :unprocessable_entity
    end
  end
  
  # DELETE /api/memberships/:id
  def destroy
    @membership.destroy
    head :no_content
  end
  
  # GET /api/memberships/active
  def active
    @memberships = Membership.active.includes(:user)
    render json: @memberships.map { |m| membership_json(m) }
  end
  
  # POST /api/memberships/batch_create
  def batch_create
    created_memberships = []
    errors = []
    
    params[:memberships].each do |membership_data|
      user = User.find_by(id: membership_data[:user_id])
      next errors << "User #{membership_data[:user_id]} not found" unless user
      
      # 기존 활성 멤버십 비활성화
      user.memberships.active.update_all(status: 'expired')
      
      membership = user.memberships.build(
        membership_type: membership_data[:membership_type],
        start_date: membership_data[:start_date] || Date.current,
        price: membership_data[:price],
        status: 'active'
      )
      
      # 자동으로 종료일 설정
      duration = Membership::DURATION_DAYS[membership.membership_type] || 30
      membership.end_date = membership.start_date + duration.days
      
      if membership.save
        created_memberships << membership
      else
        errors << "Failed to create membership for user #{user.id}: #{membership.errors.full_messages.join(', ')}"
      end
    end
    
    render json: {
      created: created_memberships.map { |m| membership_json(m) },
      errors: errors,
      summary: {
        total_requested: params[:memberships].size,
        successfully_created: created_memberships.size,
        failed: errors.size
      }
    }
  end
  
  private
  
  def set_user
    @user = User.find(params[:user_id])
  end
  
  def set_membership
    @membership = Membership.find(params[:id])
  end
  
  def membership_params
    params.require(:membership).permit(:membership_type, :start_date, :end_date, :price, :status)
  end
  
  # membership_json 메서드는 MembershipJsonHelper에서 제공
end