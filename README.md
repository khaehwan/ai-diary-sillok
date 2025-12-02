# Diary For Me

AI 기반 자동 일기 생성 앱

## 프로젝트 개요

### 소개

하루 동안 수집한 개인 데이터(알림, 위치, 사진)를 AI가 분석하여 자동으로 일기를 생성해주는 Flutter 모바일 앱입니다.

사용자의 하루를 타임라인으로 정리하고, 감성적인 일기 본문과 함께 이미지, 배경음악까지 자동 생성합니다.

### 기술 스택

#### Frontend (Flutter App)

| 분류 | 기술 |
|------|------|
| Framework | Flutter 3.10.1+, Dart |
| Local DB | Isar (NoSQL) |
| 데이터 수집 | flutter_notification_listener_plus, geolocator, photo_manager |
| 백그라운드 | flutter_background_service, flutter_local_notifications |
| 지도 | flutter_naver_map |
| 네트워크 | Dio |

#### Backend (FastAPI)

| 분류 | 기술 |
|------|------|
| Framework | FastAPI (Python) |
| 텍스트 생성 | GPT-4.1 (OpenAI) |
| 이미지 생성 | gpt-image-1 (OpenAI) |
| 음악 생성 | Lyria RealTime (Google Gemini) |

### 작동 흐름

```
1. 데이터 수집 (06:00 ~ 21:00)
   ├── 앱 알림 수집 → Isar DB 저장
   ├── 위치 정보 수집 → Isar DB 저장
   └── 사진 수집 → 서버 업로드 → URL 저장

2. 타임라인 생성 (21:00 이후)
   ├── 수집된 데이터 취합
   ├── POST /api/v1/timeline → GPT-4.1 분석
   └── 이벤트 타임라인 생성 → Isar DB 저장

3. 일기 생성 (사용자 요청 시)
   ├── 타임라인 + 기분/메모 입력
   ├── POST /api/v1/diary → 일기 본문 생성
   ├── (선택) 이미지 생성 (gpt-image-1)
   ├── (선택) 배경음악 생성 (Lyria RealTime)
   └── 완성된 일기 → Isar DB 저장
```

## Frontend(/diary_for_me) 실행 방법

### 1. Flutter 설치

```bash
# Flutter SDK 설치 (https://docs.flutter.dev/get-started/install)

# 설치 확인
flutter doctor
```

### 2. 프로젝트 설정

```bash
cd diary_for_me

# 의존성 설치
flutter pub get

# Isar 스키마 생성 (필수)
dart run build_runner build
```

### 3. 환경 변수 설정

`diary_for_me/.env` 파일 생성:

```env
# 백엔드 서버 주소
BASE_URL=http://your_server_ip:8000

# 네이버 클라우드 플랫폼 - Maps API 키
# https://console.ncloud.com/naver-service/application
NAVER_CLIENT_ID=your_naver_client_id
```

**네이버 클라우드 API 키 발급:**

1. [네이버 클라우드 플랫폼](https://console.ncloud.com) 접속
2. Services → AI·NAVER API → Application 등록
3. Maps (Mobile Dynamic Map) 선택
4. 발급된 Client ID를 `.env`에 입력

### 4. 앱 실행

```bash
# 디버그 모드 실행
flutter run

# 특정 디바이스에서 실행
flutter run -d android
flutter run -d ios

# 릴리즈 빌드
flutter build apk          # Android
flutter build ios          # iOS
```

## Backend (API Server) 실행 방법

### 1. Python 환경 설정

```bash
# Python 3.10 이상 필요
python --version

# 가상환경 생성 (권장)
python -m venv venv

# 가상환경 활성화
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate
```

### 2. 패키지 설치

```bash
cd backend

# 의존성 설치
pip install -r requirements.txt
```

### 3. 환경 변수 설정

`backend/.env` 파일 생성:

```env
# OpenAI API 키 (필수)
# https://platform.openai.com/api-keys
OPENAI_API_KEY=sk-your_openai_api_key

# Google Gemini API 키 (음악 생성용, 선택)
# https://aistudio.google.com/app/apikey
GEMINI_API_KEY=your_gemini_api_key
```

**API 키 발급:**

1. **OpenAI API 키** (필수)
   - [OpenAI Platform](https://platform.openai.com/api-keys) 접속
   - API Keys → Create new secret key
   - 타임라인/일기 텍스트 생성, 이미지 생성에 사용

2. **Google Gemini API 키** (선택)
   - [Google AI Studio](https://aistudio.google.com/app/apikey) 접속
   - Get API Key → Create API key
   - 배경음악 생성(Lyria RealTime)에 사용

### 4. 서버 실행

```bash
cd backend/api-server

# 개발 서버 실행 (자동 리로드)
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 프로덕션 실행
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 5. API 문서 확인

서버 실행 후 브라우저에서:

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API 엔드포인트

| Endpoint | Method | 설명 |
|----------|--------|------|
| `/api/v1/timeline` | POST | 일일 데이터로 타임라인 생성 |
| `/api/v1/diary` | POST | 타임라인으로 일기 생성 |
| `/api/v1/upload` | POST | 파일 업로드 (자동 분류) |
| `/api/v1/upload/image` | POST | 이미지 업로드 |
| `/api/v1/upload/music` | POST | 오디오 업로드 |
| `/api/v1/files/{category}/{filename}` | GET | 파일 다운로드 |
| `/api/v1/files/{category}/{filename}` | DELETE | 파일 삭제 |
| `/api/v1/health` | GET | 서버 상태 확인 |

## 프로젝트 구조

```
FrontendForMe/
├── diary_for_me/          # Flutter 앱
│   ├── lib/
│   │   ├── main.dart      # 앱 진입점
│   │   ├── DB/            # Isar 데이터베이스 모델
│   │   ├── api_service/   # 백엔드 API 연동
│   │   ├── collect/       # 백그라운드 데이터 수집
│   │   ├── home/          # 홈 화면
│   │   ├── timeline/      # 타임라인 편집
│   │   ├── diary/         # 일기 보기/편집
│   │   ├── new_diary/     # 일기 생성 플로우
│   │   └── my_library/    # 일기 목록
│   └── .env               # 환경 변수
│
├── backend/               # FastAPI 서버
│   ├── api-server/
│   │   ├── main.py        # FastAPI 앱
│   │   └── routes.py      # API 라우트
│   ├── models.py          # Pydantic 모델
│   ├── timeline_generator.py  # 타임라인 생성
│   ├── diary_generator.py     # 일기 생성
│   ├── storage/           # 파일 저장소
│   └── .env               # 환경 변수
│
└── README.md
```

## 라이선스

MIT License
