# frozen_string_literal: true

module Api
  class AuthController < ApplicationController
    skip_before_action :verify_authenticity_token

    # POST /api/auth/login
    def login
      email = params[:email]
      # 비밀번호 파라미터는 받지만 실제로는 사용하지 않음

      # DB에서 이메일로 사용자 검색
      user = User.find_by(email: email)

      if user
        # 사용자가 존재하면 로그인 성공
        token = generate_token(user)
        render json: {
          success: true,
          message: '로그인 성공',
          data: {
            user: user_json(user),
            token: token
          }
        }
      else
        # 사용자가 존재하지 않으면 실패
        render json: {
          success: false,
          message: '등록되지 않은 이메일입니다.'
        }, status: :unauthorized
      end
    end

    # GET /api/auth/me
    def me
      token = extract_token_from_header

      if token && (user = verify_token(token))
        render json: user_json(user)
      else
        render json: {
          success: false,
          message: '유효하지 않은 토큰입니다.'
        }, status: :unauthorized
      end
    end

    private

    def user_json(user)
      {
        id: user.id,
        email: user.email,
        name: user.name,
        created_at: user.created_at,
        updated_at: user.updated_at
      }
    end

    def generate_token(user)
      # 간단한 토큰 생성 (실제로는 JWT 등 사용)
      "token_#{user.id}_#{Time.current.to_i}_#{SecureRandom.hex(8)}"
    end

    def extract_token_from_header
      auth_header = request.headers['Authorization']
      return nil unless auth_header

      # "Bearer token" 형식에서 토큰 추출
      auth_header.split(' ').last if auth_header.start_with?('Bearer ')
    end

    def verify_token(token)
      # 간단한 토큰 검증 (실제로는 더 안전한 방식 사용)
      return nil unless token.start_with?('token_')

      parts = token.split('_')
      return nil unless parts.length >= 4

      user_id = parts[1].to_i
      User.find_by(id: user_id)
    rescue StandardError
      nil
    end
  end
end
