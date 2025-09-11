# Ringle AI 영어 회화 플랫폼

AI와 음성으로 영어 회화를 연습할 수 있는 웹 애플리케이션입니다.

## 🏗 아키텍처

### 전체 구조
```
├── backend/        # Rails API 서버
├── frontend/       # React SPA 
└── docker-compose.yml
```

### 기술 스택

#### Backend (Ruby on Rails)
- **Ruby 3.3** + **Rails 7.0**
- **PostgreSQL** - 메인 데이터베이스
- **Redis** - 메시지 캐싱 및 세션 저장소
- **Sidekiq** - 백그라운드 작업 처리
- **Google Gemini API** - AI 대화 생성
- **Docker** - 컨테이너화 환경

#### Frontend (React)
- **React 19** + **TypeScript**
- **React Router v7** - SPA 라우팅
- **Tailwind CSS** - 스타일링
- **Web Speech API** - 음성 인식/합성
- **RecordRTC** - 오디오 녹음
- **WaveSurfer.js** - 오디오 시각화

## 실행 방법

### 전체 환경 실행 (권장)
```bash
# 루트 디렉토리에서
docker-compose up -d
```

### 개별 실행

#### Backend
```bash
cd backend
bundle install
rails db:create db:migrate db:seed
rails server -p 3001
```

#### Frontend 
```bash
cd frontend/fingle
npm install
npm start
```

## 🗄 데이터베이스 구조

### 주요 테이블
- **users** - 사용자 정보
- **memberships** - 멤버십 관리 
- **conversations** - 대화 세션
- **messages** - 대화 메시지 (텍스트 + 오디오)
- **coupons** - 할인 쿠폰

### 특별한 설계
- **메시지 캐싱**: Redis에 임시 저장 → Sidekiq으로 PostgreSQL에 배치 저장(채팅 데이터)
- **오디오 처리**: Active Storage로 음성 파일 관리
- **멤버십 시스템**: 시간 기반 구독 모델

## 테스트

### Backend 테스트
```bash
cd backend
rails test                    # 전체 테스트
rails test:system            # 시스템 테스트
rails test test/services/    # 서비스 레이어 테스트
```

### Frontend 테스트
```bash
cd frontend/fingle
npm test                     # 전체 테스트
npm test -- --coverage      # 커버리지 포함
```

#### 테스트 현황
- ✅ **Setup & Mock Tests**: 4/4 통과
- ✅ **API Service Tests**: 9/9 통과  
- ✅ **App Render Tests**: 1/1 통과
- ⚠️ **Component Tests**: 6/21 통과 (UI 통합 테스트 보완 필요)

**총 20/35 테스트 통과 (57%)**

## 🔧 주요 기능

### 1. 음성 기반 AI 대화
- **Speech-to-Text**: Web Speech API 활용
- **AI 응답**: Google Gemini로 자연스러운 대화 생성
- **Text-to-Speech**: 브라우저 내장 TTS 엔진

### 2. 실시간 메시지 처리
- **Redis 캐싱**: 대화 중 빠른 응답을 위한 임시 저장
- **배치 처리**: Sidekiq으로 매시간 PostgreSQL에 영구 저장
- **오디오 저장**: 음성 파일의 안전한 클라우드 저장

### 3. 멤버십 & 결제
- **구독 관리**: 베이직/프리미엄 플랜
- **결제 연동**: Toss Payments API (Mock 구현)
- **쿠폰 시스템**: 할인 코드 지원

## 백그라운드 작업

### Sidekiq 작업들
- **MessageFlushJob**: 매시간 Redis 메시지를 PostgreSQL로 이전
- **Sidekiq-Cron**: 스케줄링된 작업 관리

### 실행 확인
```bash
# Sidekiq 웹 UI 
open http://localhost:4567

# Redis 상태 확인
redis-cli ping
```

## 🌐 배포

### Docker로 배포
```bash
docker-compose -f docker-compose.yml up -d
```

### 환경 변수
```bash
# Backend (.env)
DATABASE_URL=postgresql://user:pass@localhost/ringle_production
REDIS_URL=redis://localhost:6379
GEMINI_API_KEY=your_gemini_key (GITHUB SecretsKey 관리)

# Frontend (.env)
REACT_APP_API_BASE_URL=https://api.yourapp.com
```

### 프론트엔드 상태 관리
- **AuthContext**: 사용자 인증 상태
- **Local State**: 컴포넌트별 UI 상태
- **API Service**: 중앙화된 HTTP 요청 관리

---

**개발 환경**: macOS/Linux 권장 | **Node.js**: v18+ | **Ruby**: 3.4.5 | **Docker**: 20.10+
