# frozen_string_literal: true

module Api
  class CouponsController < ApplicationController
    before_action :set_user
    before_action :set_coupon, only: %i[show destroy]

    # GET /api/users/:user_id/coupons
    def index
      @coupons = @user.coupons.order(:created_at)
      render json: @coupons.map { |coupon| coupon_json(coupon) }
    end

    # GET /api/users/:user_id/coupons/:id
    def show
      render json: coupon_json(@coupon)
    end

    # POST /api/users/:user_id/coupons
    def create
      @coupon = @user.coupons.build(coupon_params)
      if @coupon.save
        render json: {
          success: true,
          message: '쿠폰이 생성되었습니다.',
          data: coupon_json(@coupon)
        }, status: :created
      else
        render json: {
          success: false,
          message: '쿠폰 생성에 실패했습니다.',
          errors: @coupon.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    # DELETE /api/users/:user_id/coupons/:id
    def destroy
      if @coupon.destroy
        render json: {
          success: true,
          message: '쿠폰이 삭제되었습니다.'
        }
      else
        render json: {
          success: false,
          message: '쿠폰 삭제에 실패했습니다.',
          errors: @coupon.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    # GET /api/users/:user_id/coupons/available
    def available
      @coupons = @user.coupons.active.with_remaining_uses.order(:created_at)
      render json: {
        success: true,
        data: @coupons.map { |coupon| coupon_json(coupon) },
        total_available: @coupons.count,
        has_available: @coupons.exists?
      }
    end

    private

    def set_user
      @user = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        message: '사용자를 찾을 수 없습니다.'
      }, status: :not_found
    end

    def set_coupon
      @coupon = @user.coupons.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        message: '쿠폰을 찾을 수 없습니다.'
      }, status: :not_found
    end

    def coupon_params
      params.require(:coupon).permit(:name, :total_uses, :expires_at)
    end

    def coupon_json(coupon)
      {
        id: coupon.id,
        name: coupon.name,
        total_uses: coupon.total_uses,
        used_count: coupon.used_count,
        remaining_uses: coupon.remaining_uses,
        expires_at: coupon.expires_at.iso8601,
        status: coupon.status,
        usable: coupon.usable?,
        created_at: coupon.created_at.iso8601,
        updated_at: coupon.updated_at.iso8601
      }
    end
  end
end
