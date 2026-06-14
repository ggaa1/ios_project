## MyRoutine 💧🌙

> iOS 프로그래밍 기말 프로젝트 — **수분 섭취 · 수면 습관 관리 앱**

매일의 물 섭취량과 수면 기록을 간편하게 남기고, 목표 대비 진행률과 주간 통계를
한눈에 확인하는 건강 루틴 트래커입니다. 서버·로그인 없이 모든 데이터를
**기기 안에만** 저장합니다.

---

## 주요 기능

| 화면 | 설명 |
|------|------|
| **홈** | 오늘의 수분 진행률 링, 빠른 물 추가(한 잔/큰 컵/병), 어젯밤 수면 요약 |
<img width="497" height="1014" alt="스크린샷 2026-06-14 115634" src="https://github.com/user-attachments/assets/d36f2613-a01a-41aa-8db5-b4a4da67dff0" />

| **기록 · 수분** | 음료 종류(물·커피·차·주스) 선택, 빠른 추가 / 내 컵 용량 추가, 오늘 기록 목록·삭제 |
<img width="458" height="955" alt="스크린샷 2026-06-14 120648" src="https://github.com/user-attachments/assets/08cbabef-3e42-44b2-8a41-ca8364a4552f" />

| **기록 · 수면** | 취침·기상 시각, 총 수면 시간 자동 계산, 수면의 질(별점 1~5), 최근 기록 목록 |
<img width="491" height="1021" alt="스크린샷 2026-06-14 115649" src="https://github.com/user-attachments/assets/e1479662-bdff-410d-8d39-7aadb156854e" />

| **통계** | 최근 7일 수분(L)·수면(h) 막대 차트, 평균 요약 |
<img width="479" height="948" alt="스크린샷 2026-06-14 115824" src="https://github.com/user-attachments/assets/4a4c9011-d92f-4906-8dee-2ddcca5655fb" />

| **설정** | 일일 수분 목표·컵 용량, 목표 수면 시간, 수분/취침 알림 스케줄링 |
<img width="475" height="941" alt="스크린샷 2026-06-14 115837" src="https://github.com/user-attachments/assets/32c30246-545a-4ac0-ba51-6d0ddd73ef4f" />


## 스크린 흐름

```
TabView
 ├─ 홈        : 통합 대시보드(진행률 링 + 빠른 추가 + 수면 요약)
 ├─ 기록      : 세그먼트로 수분 / 수면 전환
 ├─ 통계      : 주간 수분·수면 차트 및 평균
 └─ 설정      : 목표 설정 + 로컬 알림 설정
```

## 아키텍처

UIKit 라이프사이클(`AppDelegate` / `SceneDelegate`) 위에 SwiftUI 화면을
`UIHostingController`로 호스팅하는 하이브리드 구조이며, MVVM 패턴으로 계층을 분리했습니다.

- **DATA / LOGIC** — `MyRoutineCore.swift`
  - 모델: `UserProfile`, `DrinkLog`, `SleepLog`, `DrinkType`
  - `DataStore` (`ObservableObject`): CRUD · 대시보드/통계 집계 · 영속 저장
  - `NotificationService`: 수분/취침 로컬 알림 스케줄링(`UNUserNotificationCenter`)
- **PRESENTATION** — `MyRoutineViews.swift`
  - `RootTabView` 및 홈·기록·통계·설정 화면
- **컴포넌트 / 디자인 토큰** — `MyRoutineComponents.swift`
  - `ProgressRing`, `BarChartView`, `CardView`, `QuickAddButton`, `StarRating`, `Theme`, `Format`

### 데이터 영속성

> 계획서의 **SwiftData(`@Model`)** 대신, iOS 14.5에서도 동작하도록
> `Codable` + JSON 로컬 파일 저장으로 동일한 온디바이스 저장을 구현했습니다.

`DataStore`의 `profile` / `drinks` / `sleeps`가 변경될 때마다
앱 Documents 디렉터리의 `myroutine_store.json`에 자동 저장(`didSet → save()`)되고,
앱 시작 시 동일 파일에서 복원합니다. 외부 서버나 계정이 없으므로 데이터는
오프라인에서 기기에만 보관됩니다.

### 차트 / UI

Swift Charts(iOS 16+) 대신 SwiftUI의 `Circle().trim`(진행률 링)과
`GeometryReader` 기반 막대 차트를 직접 구현해 iOS 14.5 호환성을 확보했습니다.

## 기술 스택

- **언어**: Swift 5.0
- **UI**: SwiftUI (UIKit `UIHostingController`로 호스팅)
- **최소 지원**: iOS 14.5
- **저장**: `Codable` + JSON 파일 (Documents 디렉터리)
- **알림**: `UserNotifications` (로컬 알림)
- **의존성**: 외부 라이브러리 없음 (순수 Apple 프레임워크)

## 프로젝트 구조

<img width="2816" height="1536" alt="Gemini_Generated_Image_drs81kdrs81kdrs8" src="https://github.com/user-attachments/assets/e9fcaa60-8574-45c6-a563-a083ed33dcbe" />

## 실행 방법

1. `ios/ios.xcodeproj`를 Xcode에서 엽니다.
2. iOS 14.5 이상 시뮬레이터 또는 실기기를 타겟으로 선택합니다.
3. **Run (⌘R)** 으로 빌드 및 실행합니다.

> 알림 기능은 **설정 → 알림 설정 적용**을 누르면 권한 요청 후 스케줄링됩니다.
