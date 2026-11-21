# MyWay 개발 환경 세팅 가이드 (VS Code + 터미널)

이 문서는 **새 PC에서 MyWay 프로젝트를 받아 VS Code로 개발을 시작하기까지** 필요한 모든 과정을 순서대로 설명합니다.
macOS / Windows 모두 다루며, 명령어는 터미널(macOS: 터미널·iTerm, Windows: PowerShell)에 그대로 붙여넣으면 됩니다.

> **처음이라면 0 → 1 → 2 → 3 → 4 → 5 순서대로** 진행하세요.
> Firebase 프로젝트 없이도 **로컬 에뮬레이터**만으로 앱 전체(로그인·지도·커뮤니티·포인트)를 실행해 볼 수 있습니다 (5장).
> 실제 서비스용 Firebase 연결은 6장에서 합니다.

---

## 목차

0. [한눈에 보기 (빠른 시작)](#0-한눈에-보기-빠른-시작)
1. [필요한 도구와 버전](#1-필요한-도구와-버전)
2. [도구 설치](#2-도구-설치)
3. [프로젝트 받기 & 의존성 설치](#3-프로젝트-받기--의존성-설치)
4. [VS Code 설정](#4-vs-code-설정)
5. [로컬 실행 (Firebase 에뮬레이터)](#5-로컬-실행-firebase-에뮬레이터)
6. [실제 Firebase 프로젝트 연결 & 배포](#6-실제-firebase-프로젝트-연결--배포)
7. [테스트 실행](#7-테스트-실행)
8. [프로젝트 구조](#8-프로젝트-구조)
9. [자주 쓰는 명령어 모음](#9-자주-쓰는-명령어-모음)
10. [문제 해결 (Troubleshooting)](#10-문제-해결-troubleshooting)
11. [Git 작업 흐름](#11-git-작업-흐름)

---

## 0. 한눈에 보기 (빠른 시작)

도구(1~2장)가 모두 설치되어 있다면 아래만 하면 됩니다.

```bash
# 1) 받기
git clone https://github.com/LimJongTak/mywayapp.git
cd mywayapp
git checkout ccr-049fd908-h5lr0u        # 현재 작업 브랜치 (main 에 병합되었다면 생략)

# 2) 의존성
flutter pub get
cd functions && npm install && npm run build && cd ..

# 3) 터미널 ①: 에뮬레이터 실행 (계속 켜두기)
firebase emulators:start --project demo-myway

# 4) 터미널 ②: 데모 데이터 넣기 (에뮬레이터가 "All emulators ready" 된 뒤)
cd functions && npm run seed:demo && cd ..

# 5) 터미널 ③: 앱 실행
flutter run -d chrome --dart-define=USE_EMULATOR=true
```

→ 로그인: **`demo@myway.uk` / `demo1234`** (관리자 권한 포함 데모 계정)

---

## 1. 필요한 도구와 버전

| 도구 | 권장 버전 | 용도 | 확인 명령 |
|---|---|---|---|
| Git | 최신 | 소스 관리 | `git --version` |
| **Flutter SDK** | **3.50 이상** (Dart 3.14+) | 앱 빌드/실행 | `flutter --version` |
| **Node.js** | **22.x** (LTS) | Cloud Functions, Firebase CLI | `node -v` |
| **Java (JDK)** | **21** (최소 11) | Firestore/Storage 에뮬레이터 | `java -version` |
| **Firebase CLI** | 15.x | 에뮬레이터, 배포 | `firebase --version` |
| FlutterFire CLI | 최신 | Firebase 앱 설정 파일 생성 | `flutterfire --version` |
| Google Chrome | 최신 | 웹으로 앱 실행 (가장 빠른 개발 방법) | — |
| VS Code | 최신 | 에디터 | `code --version` |
| Android Studio | 최신 | Android SDK + 에뮬레이터 (Android 실행 시) | — |
| Xcode + CocoaPods | Xcode 16+ | iOS 실행 (macOS 전용) | `xcodebuild -version`, `pod --version` |

> `pubspec.yaml` 의 `environment: sdk: ^3.14.0` 때문에 **Flutter 3.50 미만에서는 `flutter pub get` 이 실패**합니다.
> 이 프로젝트는 Flutter 3.47+ 에서 도입된 `package:material_ui` 를 사용합니다.

---

## 2. 도구 설치

### 2-1. macOS

[Homebrew](https://brew.sh) 가 없다면 먼저 설치합니다.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```bash
# Git, Node 22, Java 21
brew install git node@22 openjdk@21
brew link --overwrite node@22
sudo ln -sfn "$(brew --prefix)/opt/openjdk@21/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-21.jdk

# Flutter
brew install --cask flutter
# (또는 수동: https://docs.flutter.dev/get-started/install/macos)

# VS Code, Chrome, Android Studio
brew install --cask visual-studio-code google-chrome android-studio

# iOS 개발 시: App Store 에서 Xcode 설치 후
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
brew install cocoapods
```

### 2-2. Windows (PowerShell)

Windows 10/11 에는 `winget` 이 기본 포함되어 있습니다. **PowerShell 을 관리자 권한으로** 열고:

```powershell
winget install --id Git.Git -e
winget install --id OpenJS.NodeJS.LTS -e          # Node 22 LTS
winget install --id EclipseAdoptium.Temurin.21.JDK -e
winget install --id Microsoft.VisualStudioCode -e
winget install --id Google.Chrome -e
winget install --id Google.AndroidStudio -e
```

**Flutter** (winget 패키지가 없으므로 수동 설치):

1. https://docs.flutter.dev/get-started/install/windows 에서 최신 stable zip 다운로드
2. `C:\src\flutter` 에 압축 해제 (공백·한글이 없는 경로! `C:\Program Files` 금지)
3. 환경 변수 `Path` 에 `C:\src\flutter\bin` 추가
   (시작 → "환경 변수" 검색 → 사용자 변수 Path → 편집 → 새로 만들기)
4. **PowerShell 을 새로 열고** `flutter --version` 확인

> 또는 git 으로: `git clone -b stable https://github.com/flutter/flutter.git C:\src\flutter`

PowerShell 에서 npm 전역 명령(`firebase` 등)이 "스크립트를 실행할 수 없습니다" 오류를 내면 한 번만 실행:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### 2-3. 공통: Firebase CLI & FlutterFire CLI

```bash
npm install -g firebase-tools
firebase --version          # 15.x 확인
firebase login              # 브라우저에서 구글 로그인 (실제 Firebase 사용 시 필요)

dart pub global activate flutterfire_cli
```

`flutterfire` 명령을 찾을 수 없다면 Dart 전역 실행 경로를 PATH 에 추가하세요.

| OS | 추가할 경로 |
|---|---|
| macOS (zsh) | `echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.zshrc && source ~/.zshrc` |
| Windows | `%LOCALAPPDATA%\Pub\Cache\bin` 를 사용자 Path 에 추가 |

### 2-4. Android 설정 (Android 기기/에뮬레이터로 실행할 경우)

1. Android Studio 실행 → **More Actions → SDK Manager**
   - SDK Platforms: 최신 Android (API 35 이상) 체크
   - SDK Tools: **Android SDK Command-line Tools**, Android SDK Build-Tools, Android Emulator, Platform-Tools 체크
2. **More Actions → Virtual Device Manager** → Pixel 기기 하나 생성 (Google Play 이미지 권장)
3. 라이선스 동의:
   ```bash
   flutter doctor --android-licenses     # 모두 y
   ```

### 2-5. 설치 확인

```bash
flutter doctor -v
```

최소한 아래 항목이 ✓ 여야 합니다.

- `[✓] Flutter`
- `[✓] Chrome - develop for the web`
- `[✓] VS Code`
- (Android 개발 시) `[✓] Android toolchain`
- (iOS 개발 시, macOS) `[✓] Xcode`

```bash
node -v        # v22.x
java -version  # 21.x
firebase --version
```

---

## 3. 프로젝트 받기 & 의존성 설치

```bash
git clone https://github.com/LimJongTak/mywayapp.git
cd mywayapp

# 작업 브랜치로 이동 (main 에 병합되었다면 main 사용)
git fetch origin
git checkout ccr-049fd908-h5lr0u
```

### 의존성 설치 (총 3곳)

```bash
# ① Flutter 앱
flutter pub get

# ② Cloud Functions (TypeScript)
cd functions
npm install
npm run build        # src/*.ts → lib/*.js 컴파일 (에뮬레이터가 lib 를 실행)
cd ..

# ③ 보안 통합 테스트 (선택 — 테스트를 돌릴 때만)
cd security-tests
npm install
cd ..
```

> `functions/.env` (운영: App Check 강제) 와 `functions/.env.local` (에뮬레이터: App Check 해제) 은
> 비밀값이 아닌 설정 플래그라 저장소에 포함되어 있습니다. 따로 만들 필요 없습니다.

---

## 4. VS Code 설정

```bash
code .          # 프로젝트 루트에서 VS Code 열기
```

> `code` 명령이 없다면: VS Code → `Cmd/Ctrl + Shift + P` → **"Shell Command: Install 'code' command in PATH"**

### 4-1. 추천 확장 설치

프로젝트를 열면 오른쪽 아래에 **"이 저장소에 권장되는 확장이 있습니다"** 알림이 뜹니다 → **모두 설치**.
(`.vscode/extensions.json` 에 정의)

| 확장 | 용도 |
|---|---|
| **Flutter** / **Dart** | 필수. 실행·디버깅·핫 리로드·자동완성 |
| Firebase (toba.vsfire) | `firestore.rules`, `storage.rules` 문법 강조 |
| ESLint, Prettier | Functions TypeScript |
| Error Lens | 오류를 코드 옆에 바로 표시 |

### 4-2. 저장소에 포함된 VS Code 설정

| 파일 | 내용 |
|---|---|
| `.vscode/launch.json` | **실행 구성** — 실행 및 디버그(`Cmd/Ctrl+Shift+D`) 패널에서 선택 후 F5 |
| `.vscode/tasks.json` | **작업** — `Cmd/Ctrl+Shift+P` → "Tasks: Run Task" |
| `.vscode/settings.json` | 저장 시 자동 포맷, 줄 길이 100, 빌드 폴더 숨김 |

**실행 구성 (launch.json)**

| 이름 | 설명 |
|---|---|
| MyWay (Chrome · 에뮬레이터) | 가장 빠른 개발용. 로컬 에뮬레이터에 연결된 웹 앱 |
| MyWay (현재 기기 · 에뮬레이터) | 하단 상태바에서 고른 기기(Android 에뮬레이터, iOS 시뮬레이터)로 실행 |
| MyWay (현재 기기 · 실제 Firebase) | 6장 설정 후, 실제 Firebase 프로젝트에 연결 |
| MyWay (Chrome · 실제 Firebase + App Check) | 웹 배포 전 확인용. `RECAPTCHA_SITE_KEY` 값을 실제 키로 바꿔서 사용 |

**작업 (tasks.json)**

| 이름 | 설명 |
|---|---|
| Firebase: 에뮬레이터 시작 | `firebase emulators:start --project demo-myway` |
| Firebase: 데모 데이터 넣기 | `functions/` 에서 `npm run seed:demo` |
| Functions: 빌드 감시 (watch) | TS 파일 저장 시 자동 컴파일 → 에뮬레이터가 자동 반영 |
| 테스트: Flutter / Functions 단위 / 보안 규칙 + Functions 통합 | 7장 참고 |

### 4-3. 실행 기기 고르기

VS Code 하단 상태바 오른쪽의 기기 이름(예: `Chrome (web-javascript)`)을 클릭 → 기기 선택.
Android 에뮬레이터는 여기서 바로 부팅할 수도 있습니다.

---

## 5. 로컬 실행 (Firebase 에뮬레이터)

Firebase 프로젝트가 없어도 **Auth · Firestore · Functions · Storage 를 내 PC에서** 그대로 돌립니다.
프로젝트 ID `demo-myway` 처럼 `demo-` 로 시작하면 Firebase 로그인 없이도 에뮬레이터가 동작합니다.

### 5-1. 순서 (터미널 3개)

**터미널 ① — 에뮬레이터 (계속 켜두기)**

```bash
firebase emulators:start --project demo-myway
```

`✔ All emulators ready!` 가 나오면 준비 완료. 브라우저에서 **http://localhost:4000** 을 열면 에뮬레이터 UI
(사용자 목록, Firestore 데이터, Functions 로그)를 볼 수 있습니다.

| 에뮬레이터 | 포트 |
|---|---|
| Emulator UI | 4000 |
| Auth | 9099 |
| Functions | 5001 |
| Firestore | 8080 |
| Storage | 9199 |
| Hosting | 5000 |

**터미널 ② — 데모 데이터 (최초 1회)**

```bash
cd functions
npm run seed:demo
```

→ `✅ 데모 데이터 생성 완료 — 로그인: demo@myway.uk / demo1234`
데모 계정(관리자), 산책로 5개(+리뷰), 편의시설, 게시글, 리워드가 생성됩니다.
(실제 프로젝트에 실수로 넣지 않도록 `demo-` 프로젝트에서만 실행되게 막혀 있습니다.)

> Functions 코드를 고치는 중이라면 이 터미널에서 `npm run build:watch` 를 켜두면 저장할 때마다 자동 반영됩니다.

**터미널 ③ — 앱 실행**

```bash
# 웹 (권장: 가장 빠름)
flutter run -d chrome --dart-define=USE_EMULATOR=true

# Android 에뮬레이터 (먼저 에뮬레이터 부팅)
flutter emulators --launch <에뮬레이터 이름>     # 목록: flutter emulators
flutter run -d emulator-5554 --dart-define=USE_EMULATOR=true

# iOS 시뮬레이터 (macOS)
open -a Simulator
flutter run -d iPhone --dart-define=USE_EMULATOR=true
```

또는 VS Code 에서 **"MyWay (Chrome · 에뮬레이터)" 선택 → F5**.

실행 중 단축키: `r` 핫 리로드, `R` 핫 리스타트, `q` 종료 (VS Code 에서는 저장 시 자동 핫 리로드).

### 5-2. 에뮬레이터 연결 방식 (참고)

`lib/main.dart` 에서 `USE_EMULATOR=true` 이면 아래 주소로 접속합니다.

| 실행 대상 | 에뮬레이터 주소 |
|---|---|
| 웹 / iOS 시뮬레이터 | `localhost` |
| Android 에뮬레이터 | `10.0.2.2` (에뮬레이터에서 PC를 가리키는 주소, 자동 처리) |
| **실제 휴대폰** | `--dart-define=EMULATOR_HOST=<PC의 IP>` 로 지정 |

실제 휴대폰에서 PC의 에뮬레이터에 붙으려면:

1. 휴대폰과 PC를 **같은 Wi-Fi** 에 연결
2. PC IP 확인 — macOS: `ipconfig getifaddr en0` / Windows: `ipconfig` (IPv4 주소)
3. `firebase.json` 의 `emulators` 각 항목에 `"host": "0.0.0.0"` 을 **임시로** 추가 후 에뮬레이터 재시작
   (같은 네트워크의 다른 기기에서도 접근 가능해지므로 작업 후 원복하고 커밋하지 마세요)
4. `flutter run -d <기기> --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.0.10`

### 5-3. 에뮬레이터 데이터 유지하기 (선택)

기본적으로 에뮬레이터를 끄면 데이터가 사라집니다. 유지하려면:

```bash
# 최초 1회
firebase emulators:start --project demo-myway --export-on-exit=./.emulator-data
# 이후
firebase emulators:start --project demo-myway --import=./.emulator-data --export-on-exit
```

`.emulator-data/` 는 `.gitignore` 에 포함되어 있습니다.

### 5-4. 이메일 인증 (에뮬레이터)

새로 이메일로 가입하면 "이메일 인증" 화면이 나옵니다. 에뮬레이터는 실제 메일을 보내지 않으므로
**에뮬레이터를 실행한 터미널 로그**에 찍힌 인증 링크를 브라우저에서 열고 → 앱에서 "인증 완료"를 누르세요.

---

## 6. 실제 Firebase 프로젝트 연결 & 배포

### 6-1. Firebase 프로젝트 만들기 (콘솔)

https://console.firebase.google.com

1. **프로젝트 추가** → 이름 입력 (예: `myway-prod`) → Google Analytics 는 선택
2. **요금제: Blaze(종량제)** 로 업그레이드 — Cloud Functions 배포에 필요 (소규모는 무료 한도 내)
3. **Authentication → 시작하기 → 로그인 방법**
   - 이메일/비밀번호: 사용 설정
   - Google: 사용 설정 (지원 이메일 선택)
4. **Firestore Database → 데이터베이스 만들기** → 위치 **`asia-northeast3 (서울)`** → 프로덕션 모드
5. **Storage → 시작하기** → 같은 위치

### 6-2. 앱과 연결

```bash
firebase login
flutterfire configure --project=<프로젝트ID>
```

- 플랫폼 선택: `android`, `ios`, `web`
- 결과로 `lib/firebase_options.dart` 가 실제 값으로 **덮어써집니다** (현재는 자리표시자)
- Android 용 `android/app/google-services.json`, iOS 용 `ios/Runner/GoogleService-Info.plist` 도 생성됩니다

`.firebaserc` 의 프로젝트 ID 도 바꿉니다.

```json
{ "projects": { "default": "<프로젝트ID>" } }
```

> `firebase_options.dart` 의 apiKey 등은 클라이언트 식별용 공개 값이라 커밋해도 됩니다.
> 실제 보안은 보안 규칙 + App Check + Functions 서버 검증이 담당합니다.
> 단, **서비스 계정 키(JSON)는 절대 커밋하지 마세요** (`.gitignore` 에 `sa.json`, `*service-account*.json` 포함).

### 6-3. Google 로그인 추가 설정

- **Android**: SHA-1 지문을 Firebase 콘솔 → 프로젝트 설정 → Android 앱 → "디지털 지문 추가"에 등록
  ```bash
  cd android && ./gradlew signingReport && cd ..      # Windows: .\gradlew signingReport
  ```
  `Variant: debug` 의 `SHA1` 값을 복사. 등록 후 `flutterfire configure` 를 다시 실행.
- **Web**: Authentication → 설정 → 승인된 도메인에 배포 도메인 추가 (`localhost` 는 기본 포함)

### 6-4. iOS 추가 설정 (macOS)

`ios/Podfile` 을 열어 최소 버전을 15.0 이상으로 설정합니다 (Firebase 요구사항, Podfile 은 첫 iOS 빌드 때 생성됨).

```ruby
platform :ios, '15.0'
```

```bash
cd ios && pod install && cd ..
```

### 6-5. App Check 등록

콘솔 → **App Check**

| 플랫폼 | 공급자 |
|---|---|
| Android | Play Integrity |
| iOS | App Attest (DeviceCheck 대체) |
| Web | reCAPTCHA v3 — 사이트 키 발급 후 `--dart-define=RECAPTCHA_SITE_KEY=...` 로 전달 |

- Cloud Functions 는 `functions/.env` 의 `ENFORCE_APP_CHECK=true` 로 이미 App Check 를 강제합니다.
- Firestore / Storage 도 App Check 메뉴에서 **"적용(Enforce)"** 을 켜는 것을 권장합니다.
- **디버그 빌드**는 디버그 공급자를 사용합니다. 앱 실행 시 콘솔 로그에 찍히는 디버그 토큰을
  App Check → 앱 → ⋮ → **디버그 토큰 관리** 에 등록해야 Functions 호출이 됩니다.

### 6-6. 배포

```bash
# 보안 규칙 + 인덱스 + Storage 규칙 + Functions
firebase deploy --only firestore,storage,functions

# 웹 앱 (Firebase Hosting)
flutter build web --release --dart-define=RECAPTCHA_SITE_KEY=<사이트키>
firebase deploy --only hosting
```

### 6-7. 초기 데이터 & 관리자 지정

서비스 계정 키 발급: 콘솔 → 프로젝트 설정 → 서비스 계정 → **새 비공개 키 생성** → 프로젝트 루트에 `sa.json` 으로 저장 (커밋 금지).

```bash
cd functions

# macOS / Linux
GOOGLE_APPLICATION_CREDENTIALS=../sa.json npm run seed                              # 편의시설 + 리워드
GOOGLE_APPLICATION_CREDENTIALS=../sa.json npm run grant-admin -- admin@example.com  # 관리자 지정

# Windows PowerShell
$env:GOOGLE_APPLICATION_CREDENTIALS="..\sa.json"; npm run seed
$env:GOOGLE_APPLICATION_CREDENTIALS="..\sa.json"; npm run grant-admin -- admin@example.com
```

관리자로 지정된 계정은 **앱에서 로그아웃 후 다시 로그인**해야 권한이 반영됩니다.

### 6-8. 앱 빌드 (스토어 배포용)

```bash
flutter build appbundle --release      # Android (Play 스토어용 .aab)
flutter build ipa --release            # iOS (macOS, Apple 개발자 계정 필요)
```

Android 릴리스 서명 설정은 https://docs.flutter.dev/deployment/android 참고.

---

## 7. 테스트 실행

```bash
# Flutter: 정적 분석 + 단위 테스트
flutter analyze
flutter test

# Functions: 포인트 정책 / 산책 검증 단위 테스트
cd functions && npm test && cd ..

# 보안 규칙 + Functions 통합 테스트 (에뮬레이터를 자동으로 띄웠다 끔, 43개)
#   ※ 5장의 에뮬레이터가 켜져 있으면 포트 충돌 → 먼저 끄고 실행
cd security-tests && npm test && cd ..
```

VS Code 에서는 "Tasks: Run Task" → `테스트: ...` 로 실행할 수 있습니다.
Flutter 테스트는 테스트 파일 위의 `Run | Debug` 버튼으로도 실행됩니다.

> `security-tests` 의 `test:sandbox` 스크립트와 `loopback-no-proxy.cjs` 는 프록시가 있는 클라우드 개발 환경 전용입니다. 일반 PC에서는 `npm test` 를 쓰세요.

---

## 8. 프로젝트 구조

```
mywayapp/
├─ lib/                         Flutter 앱
│  ├─ main.dart                 Firebase 초기화, App Check, 에뮬레이터 연결
│  ├─ app.dart                  라우팅(go_router) + 로그인/프로필 가드
│  ├─ firebase_options.dart     flutterfire configure 로 생성 (현재 자리표시자)
│  ├─ core/                     theme(디자인 토큰), geo(거리 계산), validators, errors
│  ├─ models/                   Trail, Post, AppUser, Facility ...
│  ├─ services/                 Firestore / Storage / Functions 호출 계층
│  ├─ screens/                  auth · home · map · trail · search · community · mypage · admin
│  └─ widgets/                  공통 UI 컴포넌트 (TrailCard, CategoryPill, MenuTile ...)
├─ functions/                   Cloud Functions (TypeScript)
│  ├─ src/index.ts              가입/추천인, 산책 검증·포인트, 리워드, 조회수, 집계 트리거
│  ├─ src/rules.ts              포인트 정책 · 산책 검증 순수 로직
│  ├─ src/scripts/              seed, seedDemo, grantAdmin
│  ├─ .env / .env.local         App Check 강제 여부 (운영 / 에뮬레이터)
│  └─ lib/                      빌드 결과 (git 제외)
├─ security-tests/              보안 규칙 + Functions 통합 테스트
├─ test/                        Flutter 단위 테스트
├─ firestore.rules              Firestore 보안 규칙
├─ storage.rules                Storage 보안 규칙
├─ firestore.indexes.json       복합 인덱스
├─ firebase.json                배포 / 에뮬레이터 / 호스팅 보안 헤더 설정
├─ .vscode/                     실행 구성, 작업, 추천 확장, 에디터 설정
├─ android/ ios/ web/           플랫폼별 설정 (위치 권한 등 이미 반영됨)
└─ docs/screenshots/            화면 캡처
```

---

## 9. 자주 쓰는 명령어 모음

| 작업 | 명령 |
|---|---|
| 의존성 설치/갱신 | `flutter pub get` · `cd functions && npm install` |
| 연결된 기기 목록 | `flutter devices` |
| 웹 + 에뮬레이터 실행 | `flutter run -d chrome --dart-define=USE_EMULATOR=true` |
| 에뮬레이터 시작 | `firebase emulators:start --project demo-myway` |
| 데모 데이터 | `cd functions && npm run seed:demo` |
| Functions 자동 빌드 | `cd functions && npm run build:watch` |
| 코드 포맷 | `dart format lib test` |
| 정적 분석 | `flutter analyze` |
| 캐시 꼬였을 때 | `flutter clean && flutter pub get` |
| 패키지 업데이트 확인 | `flutter pub outdated` |
| 규칙만 배포 | `firebase deploy --only firestore:rules,storage` |
| Functions 만 배포 | `firebase deploy --only functions` |
| Functions 운영 로그 | `firebase functions:log` |

---

## 10. 문제 해결 (Troubleshooting)

**`flutter pub get` — "The current Dart SDK version is X. Because myway requires SDK version ^3.14.0..."**
→ Flutter 가 오래됨. `flutter upgrade` 후 `flutter --version` 으로 3.50 이상인지 확인.

**`Target of URI doesn't exist: 'package:material_ui/material_ui.dart'`**
→ 위와 같은 원인(구버전 Flutter). `flutter upgrade` → `flutter pub get`.

**에뮬레이터 시작 시 `Could not spawn java` / `java: command not found`**
→ JDK 21 설치 후 터미널을 새로 열기. `java -version` 확인. Windows 는 `JAVA_HOME` 환경 변수도 설정.

**`Port 8080 is not open` / 포트 사용 중**
→ 이전 에뮬레이터가 남아 있음. 터미널에서 `Ctrl+C` 로 종료하거나:
macOS `lsof -i :8080` 후 `kill <PID>` / Windows `netstat -ano | findstr :8080` 후 `taskkill /PID <PID> /F`

**앱에서 Functions 호출 시 `unauthenticated` 또는 App Check 오류**
- 에뮬레이터: `--dart-define=USE_EMULATOR=true` 를 빠뜨렸는지 확인
- 실제 Firebase + 디버그 빌드: 6-5 의 **디버그 토큰 등록** 필요

**앱이 실제 Firebase 에 붙으려다 `REPLACE_ME` / API key 오류**
→ `lib/firebase_options.dart` 가 자리표시자 상태. 에뮬레이터로 실행하거나 6-2 의 `flutterfire configure` 실행.

**Android 에뮬레이터에서 에뮬레이터 서버 연결 실패**
→ 자동으로 `10.0.2.2` 를 쓰므로 PC 쪽 에뮬레이터가 켜져 있는지 확인. 실제 휴대폰이면 5-2 참고.

**iOS `pod install` 오류 / `requires a higher minimum iOS deployment version`**
→ `ios/Podfile` 의 `platform :ios, '15.0'` 설정 후 `cd ios && pod repo update && pod install`.

**Windows: `firebase` / `flutterfire` 명령을 찾을 수 없음 또는 "스크립트를 실행할 수 없습니다"**
→ 2-2 의 `Set-ExecutionPolicy` 실행, 2-3 의 PATH 설정 후 PowerShell 재시작.

**Google 로그인 실패 (Android, `ApiException: 10`)**
→ SHA-1 미등록. 6-3 참고.

**지도가 회색으로만 보임**
→ OpenStreetMap 타일 서버(`tile.openstreetmap.org`)에 접속할 수 없는 네트워크(회사/학교 방화벽 등). 다른 네트워크에서 확인.
트래픽이 커지면 `lib/widgets/map_tiles.dart` 에서 상용 타일 서버로 교체하세요.

**위치 권한 거부로 GPS 기록이 안 됨**
→ 기기 설정에서 MyWay 위치 권한 허용. 웹은 `localhost` 또는 HTTPS 에서만 위치 API 가 동작합니다.

**Functions 코드 수정이 반영되지 않음**
→ 에뮬레이터는 `functions/lib`(빌드 결과)를 실행합니다. `npm run build` 또는 `npm run build:watch`.

**뭔가 이상하게 꼬였을 때 (최후의 수단)**
```bash
flutter clean && flutter pub get
cd functions && rm -rf node_modules lib && npm install && npm run build && cd ..
# Windows: Remove-Item -Recurse -Force node_modules, lib
```

---

## 11. Git 작업 흐름

```bash
git pull                                  # 최신 받기
git checkout -b feature/<작업이름>         # 기능 브랜치 생성

# ... 작업 ...
flutter analyze && flutter test           # 커밋 전 확인
git add -A
git commit -m "기능: 산책로 공유 버튼 추가"
git push -u origin feature/<작업이름>      # GitHub 에서 Pull Request 생성
```

커밋하면 안 되는 것 (이미 `.gitignore` 처리됨): `build/`, `.dart_tool/`, `node_modules/`, `functions/lib/`,
`.emulator-data/`, 서비스 계정 키(`sa.json`), `*-debug.log`.

---

### 참고 문서

- Flutter 설치: https://docs.flutter.dev/get-started/install
- Flutter + VS Code: https://docs.flutter.dev/tools/vs-code
- FlutterFire: https://firebase.google.com/docs/flutter/setup
- Firebase 에뮬레이터: https://firebase.google.com/docs/emulator-suite
- App Check: https://firebase.google.com/docs/app-check
- 프로젝트 기능/보안 설계: [README.md](README.md)
