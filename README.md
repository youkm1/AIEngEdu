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
- **Dependabot** - gem automating dependency management

#### Frontend (React)
- **React 19** + **TypeScript**
- **React Router v7** - SPA 라우팅
- **Tailwind CSS** - 스타일링
- **Web Speech API** - 음성 인식/합성
- **RecordRTC** - 오디오 녹음
- **WaveSurfer.js** - 오디오 시각화

## 실행 방법

### Docker로 전체 환경 실행 (권장)
```bash
# 1. 백엔드 디렉토리로 이동
cd backend

# 2. 환경변수 파일 생성
cp .env.example.template .env.development

# 3. .env.development 파일을 열어서 실제 API 키 설정
# GEMINI_API_KEY=api_key_here

# 4. Docker Compose로 전체 환경 실행
docker-compose up -d
```

실행 후 다음 서비스들이 시작됩니다:
- **Rails API**: http://localhost:3001
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **Sidekiq**: 백그라운드 작업 처리

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

**Frontend (React/TypeScript)**
- **Setup & Mock Tests**: 4/4 통과
- **API Service Tests**: 9/9 통과  
- **App Render Tests**: 1/1 통과
- **Home Component Tests**: 12/12 통과
- **Chat Component Tests**: 9/9 통과

**Frontend 총합: 35/35 테스트 통과 (100%)**

**Backend (Ruby on Rails)**
- **Model Tests**: 전체 통과 (Membership 모델 포함)
- **Service Tests**: 전체 통과 (MessageCacheService, MockTossPaymentsService 포함)
- **Controller Tests**: 전체 통과 (Admin Memberships API 포함)
- **Job Tests**: 전체 통과 (MessageFlushJob 포함)
- **Integration Tests**: 전체 통과 (멤버십 결제 플로우 포함)

**주요 백엔드 테스트 기능:**
-  **멤버십 할당**: 어드민 멤버십 부여 API (인증/인가, 할당/삭제)
-  **유저 결제 API**: 멤버십 결제 진행, 토스 페이먼츠 Mock 연동
-  **PG사 결제 API**: Mock 객체를 통한 결제 시뮬레이션 테스트

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

### Docker 파일 구조

**개발 환경:**
- `Dockerfile.dev`: 개발용 (Ruby 3.4.5, 빠른 빌드)
- `docker-compose.yml`: 개발 환경 전체 오케스트레이션

**프로덕션 환경:**
- `Dockerfile`: 프로덕션 최적화 (멀티스테이지 빌드, 보안)
- Kamal 배포 또는 수동 빌드

```bash
# 개발환경
docker-compose up -d

# 프로덕션 빌드
docker build -t ringle_task .
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

**Node.js**: v18+ | **Ruby**: 3.4.5 | **Docker**: 20.10+
