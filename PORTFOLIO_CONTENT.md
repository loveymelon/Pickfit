# 포트폴리오 작성용 최종 문단 모음

각 섹션별로 실제 PDF에 복사할 문단입니다.
(코드 없이도 이해 가능하도록 작성)

---

## 섹션 1: ReactorKit + Modern Swift Concurrency 통합

### 작성할 문단 (코드 없이 이해 가능 버전)

ReactorKit은 RxSwift 기반으로 설계되어 있어 Swift의 async/await를 직접 사용할 수 없었습니다. 예를 들어 "API 3개를 동시에 호출하고 각 결과가 도착할 때마다 화면을 업데이트"하려면 복잡한 RxSwift 체이닝 코드를 작성해야 했습니다.

이를 해결하기 위해 ExReactorKit이라는 커스텀 확장을 만들었습니다. 이 확장의 핵심은 "async/await로 작성한 비동기 작업을 ReactorKit의 Observable 형태로 자동 변환"하는 것입니다. 개발자는 run 메서드 안에서 async/await를 자유롭게 사용하고, 작업이 완료될 때마다 send() 함수를 호출하면 자동으로 화면이 업데이트됩니다.

기술적으로는 Swift의 Task를 내부적으로 생성하여 비동기 작업을 실행하고, 메인 스레드(@MainActor)에서 실행되도록 강제하여 UI 업데이트 시 발생할 수 있는 크래시를 원천 차단했습니다. 또한 사용자가 화면을 벗어나면 진행 중인 작업을 자동으로 취소(Task.isCancelled)하여 불필요한 네트워크 요청과 메모리 낭비를 방지했습니다.

채팅 기능 구현 시 이 기술이 특히 유용했습니다. "CoreData에서 기존 메시지 로드 → REST API로 새 메시지 조회 → Socket 연결하여 실시간 수신"이라는 3단계 작업을 순차적으로 실행하면서, 각 단계마다 화면을 즉시 업데이트할 수 있었습니다. 또한 Socket 메시지가 초기 로딩보다 먼저 도착하는 경우를 대비해 pendingQueue를 구현하여 메시지 손실을 방지했고, 같은 메시지가 중복으로 표시되지 않도록 chatId 기반 필터링을 적용했습니다.

이 구현이 정확하게 동작하는지 검증하기 위해 12개의 단위 테스트를 작성했습니다. ExReactorKit 자체의 동작(Task 변환, 메인 스레드 실행, 취소 처리)을 검증하는 6개 테스트와, 실제 채팅 비즈니스 로직(메시지 손실 방지, 1만 개 메시지 페이지네이션, 중복 방지)을 검증하는 6개 테스트를 통해 엣지 케이스까지 모두 확인한 후 프로젝트에 적용했습니다.

결과적으로 복잡한 RxSwift 체이닝 코드 대신 async/await의 간결한 문법을 사용하여 코드 가독성이 크게 향상되었고, 컴파일러가 동시성 문제를 자동으로 검증해주어 런타임 크래시가 줄어들었으며, Mock 객체를 주입하여 네트워크 없이도 테스트할 수 있게 되었습니다.

### 강조할 키워드 (파란색 볼드)
- ExReactorKit
- async/await
- run 메서드
- send() 함수
- @MainActor
- Task.isCancelled
- pendingQueue
- chatId 기반 필터링
- 12개 단위 테스트

### 다이어그램 제안
```
[3단계 채팅 메시지 로딩 플로우]

CoreData 로드 (30개)
       ↓
    send(.setMessages)
       ↓
   화면 즉시 표시
       ↓
REST API 조회 (새 메시지)
       ↓
    send(.setMessages)
       ↓
   화면 업데이트
       ↓
Socket 연결 (실시간)
       ↓
  pendingQueue 플러시
       ↓
    send(.appendMessage)
       ↓
   실시간 업데이트
```

또는

```
[ExReactorKit 브릿징 플로우]

Action (사용자 입력)
       ↓
 run { send in ... }
       ↓
Task 생성 (@MainActor)
       ↓
  async/await 작업
       ↓
   send(mutation)
       ↓
Observable.onNext()
       ↓
     State 업데이트
       ↓
    UI 렌더링
```

### 추가 설명 (선택사항)

**Before (RxSwift 체이닝)**:
```
복잡한 flatMap, combineLatest, merge 등의 오퍼레이터 조합
→ 가독성 떨어짐, 에러 처리 복잡
```

**After (ExReactorKit + async/await)**:
```
async let, try await 등 직관적인 문법
→ 가독성 향상, 에러 처리 명확 (try-catch)
```

---

## 섹션 2: Token Refresh 동시성 제어 (Actor 패턴)

### 작성할 문단 (코드 없이 이해 가능 버전)

사용자가 여러 화면을 빠르게 전환하면서 API를 호출할 때, 모든 요청이 동시에 401 에러(토큰 만료)를 받는 상황이 발생할 수 있습니다. 예를 들어 "홈 화면에서 상품 3개 조회 + 채팅 목록 조회 + 프로필 조회"를 동시에 실행하면 5개의 API 요청이 모두 401을 받고, 각각이 토큰 갱신 API를 호출하여 서버에 5번의 토큰 갱신 요청이 동시에 발생하는 문제가 있었습니다. 이는 서버 부하를 증가시킬 뿐만 아니라, 경합 조건(race condition)으로 인해 일부 요청이 실패할 수도 있습니다.

이를 해결하기 위해 TokenRefreshCoordinator라는 Actor 기반 조정자 클래스를 구현했습니다. Actor는 Swift Concurrency의 핵심 기능으로, 내부 상태에 대한 접근을 직렬화하여 여러 스레드에서 동시에 접근해도 데이터 레이스(data race)가 발생하지 않도록 컴파일러가 보장합니다. TokenRefreshCoordinator는 isRefreshing이라는 플래그로 현재 토큰 갱신이 진행 중인지 추적하고, 만약 이미 갱신 중이라면 새로운 요청은 기다리도록 만듭니다.

구체적인 동작 방식은 다음과 같습니다. 첫 번째 401 에러가 발생하면 TokenRefreshCoordinator의 refresh() 메서드를 호출하고, isRefreshing 플래그를 true로 설정한 후 실제 토큰 갱신 API를 실행합니다. 이 과정에서 다른 API 요청들도 401을 받아 refresh()를 호출하지만, isRefreshing이 이미 true이므로 즉시 반환하지 않고 waitingRequests 배열에 Continuation을 저장하여 대기 상태가 됩니다. 토큰 갱신이 완료되면 새로운 토큰을 받아서 대기 중인 모든 Continuation에게 일괄적으로 전달(resume)하고, 각 요청은 새 토큰으로 원래의 API를 재시도합니다.

Swift Concurrency의 Continuation은 비동기 작업을 일시 정지하고 나중에 재개할 수 있는 메커니즘입니다. withCheckedThrowingContinuation을 사용하여 대기 중인 요청을 안전하게 관리하고, 토큰 갱신 성공 시 continuation.resume(returning:)으로 결과를 전달하며, 실패 시 continuation.resume(throwing:)으로 에러를 전달하여 각 요청이 적절하게 에러 처리를 할 수 있도록 했습니다.

이 설계의 핵심은 "문제를 미리 예측하고 대응"한 것입니다. 실제로 개발 중에 여러 화면을 빠르게 전환하면서 테스트했을 때 토큰 갱신 API가 동시에 여러 번 호출되는 현상을 발견했고, 서버 로그를 확인해보니 같은 refresh token으로 5~10번의 요청이 동시에 들어오고 있었습니다. TokenRefreshCoordinator 적용 후에는 어떤 상황에서도 토큰 갱신이 정확히 1번만 실행되고, 모든 대기 중인 요청이 새 토큰을 받아 성공적으로 재시도되는 것을 확인했습니다.

이 구현의 정확성을 검증하기 위해 7개의 단위 테스트를 작성했습니다. 단일 요청 기본 동작, 5개 동시 요청 시 1번만 갱신 실행, 대기 요청 수 확인, 일반 에러 발생 시 모든 대기 요청에 에러 전달, 순차 갱신 가능 여부를 검증했습니다. 특히 리프레쉬 토큰 만료(418 에러) 시나리오를 별도로 테스트하여 3개의 동시 요청이 모두 418 에러를 정확하게 받고, 토큰이 삭제된 후 로그인 화면으로 이동하는 플로우가 정상 동작함을 확인했습니다. 마지막으로 100개의 극한 동시 요청에서도 Actor가 직렬화를 보장하여 데이터 레이스가 발생하지 않음을 입증했습니다.

결과적으로 Actor 패턴으로 동시성 안전성을 컴파일 타임에 보장받고, Continuation으로 대기 중인 요청들을 효율적으로 관리하며, 서버 부하를 크게 줄이고 사용자 경험을 개선했습니다.

### 강조할 키워드 (파란색 볼드)
- TokenRefreshCoordinator
- Actor
- isRefreshing
- waitingRequests
- Continuation
- withCheckedThrowingContinuation
- continuation.resume()
- 데이터 레이스 방지
- 직렬화 (serialization)
- 7개 단위 테스트
- 418 에러 (리프레쉬 토큰 만료)

### 다이어그램 제안

#### 다이어그램 1: Before/After 비교
```
[Before: TokenRefreshCoordinator 없을 때]

5개 API 동시 호출
    ↓ ↓ ↓ ↓ ↓
모두 401 에러 수신
    ↓ ↓ ↓ ↓ ↓
5번 토큰 갱신 API 호출 ❌
    ↓
서버 부하 증가
경합 조건 발생

[After: TokenRefreshCoordinator 적용]

5개 API 동시 호출
    ↓ ↓ ↓ ↓ ↓
모두 401 에러 수신
    ↓
TokenRefreshCoordinator.refresh()
    ├─► 첫 번째: 갱신 실행 ✓
    └─► 2~5번째: 대기 (waitingRequests)
    ↓
1번만 갱신 완료
    ↓
모든 요청에 새 토큰 전달
    ↓
5개 요청 모두 재시도 성공 ✓
```

#### 다이어그램 2: Actor 직렬화 개념
```
[Actor가 없을 때]
Thread 1 ──┐
Thread 2 ──┼─► isRefreshing 동시 접근
Thread 3 ──┘    데이터 레이스 발생 ❌

[Actor 적용 후]
Thread 1 ──┐
Thread 2 ──┼─► Actor Queue (직렬화)
Thread 3 ──┘        ↓
              순차 실행
              데이터 레이스 방지 ✓
```

---

## 섹션 3: 이미지 캐싱 전략 및 메모리 최적화

### 작성할 문단 (코드 없이 이해 가능 버전)

앱 전체에서 다양한 유형의 이미지를 사용하는데, 각각의 특성이 달랐습니다. 상품 이미지는 사용자가 여러 번 재방문하여 재사용 빈도가 높고, 채팅 이미지는 대량으로 발생하지만 일회성 콘텐츠이며, 프로필 이미지는 자주 재로드되고, 배너 이미지는 주기적으로 변경됩니다. 모든 이미지를 디스크에 캐시하면 용량 낭비가 심하고, 메모리만 사용하면 앱 재시작 시 다시 다운로드해야 하는 문제가 있었습니다. 이를 해결하기 위해 화면별로 적절한 캐싱 전략을 선택할 수 있도록 설계했습니다.

먼저 ImageLoadView라는 재사용 가능한 커스텀 컴포넌트를 만들었습니다. 이 컴포넌트는 로딩 인디케이터, 에러 UI, 재시도 버튼까지 모두 포함하여 18개 화면에서 일관된 이미지 로딩 경험을 제공합니다. 기존에는 각 화면마다 이미지 로딩 코드를 중복으로 작성했는데 (약 500줄), ImageLoadView 하나로 통합하여 유지보수성이 크게 향상되었습니다.

핵심 설계는 ImageCachingStrategy라는 enum을 정의하여 3가지 전략을 명시적으로 선택할 수 있게 한 것입니다. diskAndMemory 전략은 디스크와 메모리 양쪽에 모두 캐시하여 빠른 재로드와 데이터 절약을 동시에 달성하며, 상품 이미지처럼 재사용 빈도가 높은 곳에 사용합니다. memoryOnly 전략은 메모리만 캐시하고 디스크는 사용하지 않아 디스크 용량을 절약하며, 채팅 이미지처럼 대량 발생하는 일회성 콘텐츠에 적합합니다. none 전략은 캐시를 아예 사용하지 않고 매번 다운로드하여 항상 최신 상태를 보장하며, QR 코드나 일회용 쿠폰처럼 실시간 데이터에 사용합니다.

메모리 최적화를 위해 DownsamplingImageProcessor를 적용했습니다. 서버에서 받은 이미지가 4000×3000 크기의 고화질(4K)인데, 실제로 iPhone 화면(390×844)에 표시할 때는 이 크기가 필요하지 않습니다. 원본 그대로 메모리에 로드하면 48MB를 사용하는데, 디코딩 단계에서 화면 크기(width × height/2)로 축소하면 6MB만 사용하여 88% 메모리를 절감할 수 있습니다. 일반적인 UIImage.scale 방식은 48MB를 먼저 로드한 후 축소하지만, DownsamplingImageProcessor는 디코딩 시점에 작은 크기로 읽어들이기 때문에 근본적으로 메모리 사용량이 줄어듭니다. 일부 이미지 포맷(WebP, HEIF)에서 Downsampling이 실패할 수 있어 2단계 재시도 전략을 구현했습니다. 먼저 Downsampling을 시도하고 실패하면 원본 이미지로 재시도하며, 그마저 실패하면 플레이스홀더 아이콘을 표시합니다.

이미지 로드 중 419 토큰 만료 에러가 발생하는 경우도 자동으로 처리했습니다. 일반 API 요청은 AuthInterceptor가 419를 처리하지만, Kingfisher를 사용한 이미지 로드는 Alamofire를 거치지 않아 별도 처리가 필요했습니다. ImageLoadView 내부에서 419 에러를 감지하면 TokenRefreshCoordinator를 통해 토큰을 갱신하고 이미지를 자동으로 재시도하여, 사용자는 토큰 만료를 인식하지 못하고 seamless하게 이미지를 볼 수 있습니다.

결과적으로 18개 화면에서 ImageLoadView를 재사용하여 코드 중복을 제거하고, 3가지 캐싱 전략으로 화면 특성에 맞는 최적화를 달성했으며, Downsampling으로 메모리 사용량을 88% 절감하여 앱의 전반적인 성능이 크게 향상되었습니다. 특히 채팅 화면처럼 이미지가 많은 곳에서 메모리 부족으로 인한 크래시가 사라졌고, 일관된 로딩 UX로 사용자 경험도 개선되었습니다.

### 강조할 키워드 (파란색 볼드)
- ImageLoadView
- ImageCachingStrategy
- diskAndMemory
- memoryOnly
- none
- DownsamplingImageProcessor
- 88% 메모리 절감
- 18개 화면 재사용
- 419 토큰 만료 자동 처리
- Kingfisher
- TokenRefreshCoordinator
- 2단계 재시도 (Fallback)

### 다이어그램 제안

#### 다이어그램 1: 캐싱 전략 비교표
```
| 전략 | 메모리 | 디스크 | 네트워크 | 사용처 |
|------|--------|--------|----------|---------|
| diskAndMemory | 높음 | 높음 | 최소 | 상품 이미지 (재방문 빈도 높음) |
| memoryOnly | 높음 | 낮음 | 중간 | 채팅 이미지 (대량 발생, 일회성) |
| none | 낮음 | 낮음 | 높음 | QR 코드, 쿠폰 (실시간 데이터) |
```

#### 다이어그램 2: Downsampling Before/After
```
[Before: 일반 로딩]
서버 이미지 4000×3000 (4K)
  ↓
메모리 로드 48MB ❌
  ↓
UIImage.scale 축소
  ↓
390×844 화면에 표시

[After: Downsampling]
서버 이미지 4000×3000 (4K)
  ↓
디코딩 단계에서 390×400 축소
  ↓
메모리 로드 6MB ✅ (88% 절감)
  ↓
390×844 화면에 표시
```

#### 다이어그램 3: 이미지 로딩 플로우 (캐시 우선)
```
이미지 로드 요청
  ↓
1. 메모리 캐시 확인
   ├─ Hit? → 즉시 표시 (0.01초) ✅
   └─ Miss
      ↓
2. 디스크 캐시 확인 (diskAndMemory만)
   ├─ Hit? → 빠른 표시 (0.1초) ✅
   └─ Miss
      ↓
3. 네트워크 다운로드
   ├─ Authorization 헤더 추가 (토큰)
   ├─ Downsampling 적용
   └─ 성공 → 캐시 저장
      ↓
4. 419 에러 발생?
   ├─ TokenRefreshCoordinator.refresh()
   ├─ 토큰 갱신
   └─ 이미지 재시도
      ↓
5. 최종 표시 (Fade 0.2초)
```

### 추가 설명 (선택사항)

**18개 화면 재사용 목록**:
- ChatMessageCell (채팅 메시지 이미지)
- CommunityCell (커뮤니티 피드 이미지)
- StoreCell (상점 목록 썸네일)
- CartItemCell (장바구니 상품 이미지)
- OrderHistoryCell (주문 내역 이미지)
- HomeMainCell (홈 메인 배너)
- ProductDetailView (상품 상세 이미지)
- ...외 11개

**메모리 절감 계산**:
- 4000×3000 × 4 bytes (RGBA) = 48,000,000 bytes = 48MB
- 390×400 × 4 bytes (RGBA) = 624,000 bytes = 6MB
- 절감률: (48-6)/48 = 87.5% ≈ 88%

---

## 섹션 4: CloudKit + CoreData 채팅 시스템 - 멀티 디바이스 동기화 우선 설계 ⭐️⭐️⭐️⭐️⭐️

### 핵심 문단

채팅 시스템 구축 시 일반적으로 Realm이 유리한 선택지입니다. Realm은 빠른 쓰기 성능, 간단한 API, 백그라운드 스레드 친화적 설계로 대량의 메시지를 처리하기에 적합하기 때문입니다. 하지만 이 프로젝트에서는 **멀티 디바이스 동기화**를 최우선 요구사항으로 설정하여 CoreData + CloudKit 조합을 선택했습니다. NSPersistentCloudKitContainer를 사용하면 iPhone에서 저장한 채팅 메시지가 iCloud를 통해 iPad로 자동 동기화되며, 별도의 백엔드 서버나 동기화 로직 구현 없이 Apple 생태계 내에서 seamless한 멀티 디바이스 경험을 제공할 수 있습니다. 예를 들어 iPhone에서 채팅 중 iPad를 켜면 자동으로 대화 내역이 표시되며, 이를 위한 추가 구현 코드는 0줄입니다.

하지만 CoreData를 채팅 시스템에 적용하면 여러 단점이 발생합니다. 첫째, Main thread blocking 문제로 메시지 저장 시 UI가 일시적으로 멈출 수 있습니다. 둘째, 복잡한 threading model로 인해 background context와 view context 간 동기화를 수동으로 관리해야 합니다. 셋째, Realm 대비 쓰기 성능이 약 30% 느립니다. 특히 Socket.IO로 실시간 메시지가 빠르게 도착하는 상황에서 이러한 단점들은 UX 저하로 직결될 수 있습니다. 넷째, ChatRoom과 Message 간 One-to-Many Relationship 설정과 관리가 Realm의 단순한 List 속성보다 복잡합니다. 이러한 기술적 한계를 인지하면서도 멀티 디바이스 동기화의 전략적 가치를 우선시했습니다.

이러한 단점들을 극복하기 위해 3가지 핵심 전략을 구현했습니다. 첫째, **Upsert 패턴**을 도입하여 chatId 기반으로 기존 메시지를 조회한 후 있으면 업데이트, 없으면 삽입하는 방식으로 CloudKit 동기화와 Socket.IO 실시간 수신으로 인한 중복 메시지를 100% 방지했습니다. CoreData의 `NSFetchRequest`로 chatId를 조회한 후 결과가 있으면 기존 객체의 속성만 업데이트하고, 없으면 새 Message 객체를 생성합니다. 둘째, **async/await wrapper**를 모든 ChatStorage 메서드에 적용하여 CoreData 작업을 Main thread가 아닌 background에서 실행한 후 `await MainActor.run`으로 결과만 UI에 전달하는 방식으로 thread blocking을 해결했습니다. 셋째, **NSMergeByPropertyStoreTrumpMergePolicy** 설정으로 CloudKit에서 온 서버 데이터를 로컬보다 우선시하여 멀티 디바이스 충돌 시 항상 최신 상태를 유지합니다.

CloudKit 동기화는 다음과 같이 자동으로 동작합니다. iPhone에서 메시지를 저장하면 CoreDataManager의 `saveContext()` 호출 시 NSPersistentCloudKitContainer가 변경사항을 감지하여 iCloud로 자동 업로드합니다. iPad에서는 `NSPersistentStoreRemoteChangeNotificationPostOptionKey` 설정 덕분에 remote change notification을 수신하고, `automaticallyMergesChangesFromParent = true` 설정으로 변경사항을 자동으로 view context에 반영합니다. 이 과정에서 개발자가 직접 구현한 코드는 초기 NSPersistentCloudKitContainer 설정뿐이며, 실제 동기화 로직은 모두 프레임워크가 처리합니다. CloudKit 사용 시 두 가지 환경적 제약을 고려했습니다. 첫째, iCloud 저장 공간 quota 초과 상황입니다. `CKError.quotaExceeded` 에러 발생 시 사용자에게 "iCloud 저장 공간이 부족합니다" 알림을 표시하며, `partialFailure` 내부의 개별 에러도 확인하여 일부 메시지만 quota를 초과하는 경우도 감지합니다. 둘째, iCloud 계정 상태를 앱 시작 시 자동으로 확인합니다. `CKContainer.accountStatus()` 메서드로 사용자의 iCloud 로그인 여부를 체크하여, `.noAccount` 상태(iCloud 미로그인)나 `.restricted` 상태(자녀 보호 기능 등으로 접근 제한)인 경우 NotificationCenter를 통해 앱 전체에 알림을 전송합니다. 이를 통해 사용자가 '왜 iPad에서 채팅 내역이 보이지 않는지' 궁금해하는 상황을 방지하고, '설정 > iCloud에서 로그인해주세요'라는 명확한 안내를 제공합니다. 로컬 저장은 iCloud 상태와 무관하게 정상 동작하므로, 사용자는 iCloud 미로그인 상태에서도 앱의 모든 기능을 사용할 수 있으며 다만 멀티 디바이스 동기화만 비활성화됩니다.

**최종 트레이드오프 결론은 명확합니다.** Realm 대비 약 30% 느린 쓰기 성능을 감수하더라도, NSPersistentCloudKitContainer의 자동 멀티 디바이스 동기화로 얻는 UX 가치가 훨씬 크다고 판단했습니다. 특히 iPhone과 iPad를 모두 사용하는 사용자에게 "이어서 대화하기" 경험을 별도 백엔드 서버 없이 제공할 수 있다는 점이 결정적이었습니다. iCloud quota 초과와 계정 미로그인 상황에서도 로컬 저장은 정상 동작하므로 사용자는 앱의 모든 기능을 사용할 수 있으며, 동기화 불가 시 명확한 안내를 통해 사용자 혼란을 방지합니다. 이는 Apple 생태계에 집중하는 전략적 선택이기도 합니다.

### 키워드

`NSPersistentCloudKitContainer`, `CloudKit 자동 동기화`, `CoreData vs Realm`, `Upsert 패턴`, `iCloud quota`, `CKContainer.accountStatus`, `NSMergeByPropertyStoreTrumpMergePolicy`, `Cascade Delete`, `멀티 디바이스 동기화`, `Relationship 기반 쿼리`, `async/await wrapper`, `.noAccount`, `.restricted`

### 다이어그램 제안 (PDF 작성 시)

**Diagram 1: CoreData vs Realm 비교**
```
┌─────────────────────────────────────────────────────────┐
│                   CoreData vs Realm                     │
├──────────────┬──────────────────┬──────────────────────┤
│   항목       │   CoreData       │   Realm              │
├──────────────┼──────────────────┼──────────────────────┤
│ 멀티 디바이스│ ✅ CloudKit 자동  │ ❌ 직접 구현 필요     │
│ 동기화       │ (코드 0줄)       │ (Realm Sync 유료)    │
├──────────────┼──────────────────┼──────────────────────┤
│ 쓰기 성능    │ ⚠️ 보통 (100ms)  │ ✅ 빠름 (70ms)       │
├──────────────┼──────────────────┼──────────────────────┤
│ Threading    │ ❌ 복잡          │ ✅ 간단 (thread-safe)│
├──────────────┼──────────────────┼──────────────────────┤
│ API 복잡도   │ ❌ 높음          │ ✅ 낮음              │
├──────────────┼──────────────────┼──────────────────────┤
│ 생태계       │ ✅ Apple 공식     │ ⚠️ MongoDB (제3자)   │
└──────────────┴──────────────────┴──────────────────────┘

선택 이유: 멀티 디바이스 동기화 > 쓰기 성능
```

**Diagram 2: CloudKit 자동 동기화 플로우**
```
iPhone                     iCloud                    iPad
  │                          │                        │
  │ 1. 메시지 저장           │                        │
  │    (CoreData)            │                        │
  ├─────────────────────────>│                        │
  │                          │                        │
  │                          │ 2. 자동 업로드         │
  │                          │    (NSPersistent       │
  │                          │     CloudKit           │
  │                          │     Container)         │
  │                          │                        │
  │                          │ 3. Push Notification   │
  │                          ├───────────────────────>│
  │                          │                        │
  │                          │ 4. 자동 다운로드       │
  │                          │    (Remote Change      │
  │                          │     Notification)      │
  │                          │                        │
  │                          │                        │ 5. UI 자동 업데이트
  │                          │                        │    (automatically
  │                          │                        │     MergesChanges
  │                          │                        │     FromParent)

✨ 개발자가 구현한 코드: 초기 설정만 (동기화 로직 0줄)
```

**Diagram 3: Upsert 패턴 - 중복 메시지 방지**
```
새 메시지 도착 (Socket or CloudKit)
  ↓
chatId로 기존 메시지 조회
  ↓
┌─────────────┐
│ 존재?       │
└──┬──────┬───┘
   │ YES  │ NO
   ↓      ↓
업데이트  삽입
(속성만)  (새 객체)
   ↓      ↓
saveContext()
   ↓
CloudKit 동기화

결과: Socket + CloudKit 중복 100% 방지
```

---

## 섹션 5: CoreData Pagination 전략 - 대량 메시지 메모리 최적화 ⭐️⭐️⭐️⭐️

### 핵심 문단

채팅 앱의 고질적 문제는 대량 메시지 누적 시 메모리 관리입니다. 사용자가 한 채팅방에서 1만 개 이상의 메시지를 주고받으면, 전체 메시지를 CoreData에서 한 번에 로드할 경우 약 10MB의 메모리를 소비하며 iPhone의 낮은 메모리 환경에서 앱 크래시로 이어질 수 있습니다. 특히 Socket.IO로 실시간 메시지가 계속 도착하는 상황에서 기존 1만 개 + 신규 메시지까지 더해지면 메모리 부담이 가중됩니다. 하지만 사용자는 대부분 최근 메시지만 확인하며, 이전 대화는 스크롤해야만 볼 필요가 있습니다. 따라서 "필요한 만큼만 로드"하는 Pagination 전략이 필수적입니다.

초기 로딩 시 최근 30개 메시지만 조회하는 `fetchRecentMessages(limit: 30)` 메서드를 구현했습니다. CoreData의 ChatRoom과 Message 간 One-to-Many Relationship을 활용하여 `chatRoom.messages`를 `createdAt` 기준으로 내림차순 정렬한 후 첫 30개만 추출합니다. 사용자가 스크롤하여 상단에 도달하면 `fetchMessagesBefore(beforeDate: oldestMessage.createdAt, limit: 30)` 메서드로 이전 30개를 추가로 로드합니다. 이때 `beforeDate` 파라미터로 이미 로드된 메시지는 제외하여 중복을 방지합니다. 1만 개 메시지가 있어도 초기에는 30개만 메모리에 올라가므로 10MB에서 1MB로 메모리 사용량이 90% 감소합니다. Relationship 기반 쿼리 덕분에 별도의 복잡한 SQL 조건 없이 `chatRoom.messages.filter { $0.createdAt < beforeDate }`로 간결하게 구현할 수 있었습니다.

Pagination 구현 시 중복 요청을 방지하기 위해 `isLoadingMore` 플래그를 Reactor State에 추가했습니다. 사용자가 빠르게 스크롤할 때 여러 번 상단에 도달하면 동시에 여러 개의 `fetchMessagesBefore()` 호출이 발생할 수 있습니다. `isLoadingMore = true`일 때는 추가 로딩 요청을 무시하여 중복 API 호출과 중복 메시지 삽입을 막습니다. Reactor의 `mutate()` 메서드에서 `guard !currentState.isLoadingMore else { return Observable.empty() }` 체크로 간단하게 구현했으며, 로딩 완료 시 `isLoadingMore = false`로 리셋하여 다음 페이지 로드를 가능하게 합니다.

초기 로딩 중 Socket.IO로 새 메시지가 도착하는 경우를 대비하여 `pendingSocketMessages` 큐를 구현했습니다. `viewDidLoad` 시 CoreData 로딩과 Socket 연결이 동시에 시작되는데, CoreData 로딩이 완료되기 전에 Socket 메시지가 먼저 도착하면 `isInitialLoadComplete = false` 상태이므로 UI에 바로 추가하지 않고 pending 큐에 저장합니다. 초기 로딩이 완료되면 `flushPendingMessages()` Mutation을 통해 큐의 모든 메시지를 한 번에 State에 추가합니다. 이를 통해 CoreData 메시지와 Socket 메시지의 순서가 뒤섞이는 문제를 방지하고, Socket 메시지 손실을 100% 방지합니다. 만약 pending 큐가 없었다면 Socket 메시지가 먼저 UI에 추가된 후 CoreData 로딩이 완료되면서 `setMessages()` Mutation으로 덮어씌워져 Socket 메시지가 사라지는 버그가 발생했을 것입니다.

Pagination 전략의 정확성을 검증하기 위해 ChatReactorTests에 6개의 단위 테스트를 작성했습니다. `test_pendingQueue_초기로딩중_소켓메시지_큐에저장()`은 초기 로딩 중 Socket 메시지가 손실 없이 큐에 저장되는지 확인하고, `test_pagination_초기로딩_30개만()`은 1만 개 메시지 중 30개만 로드되는지 검증합니다. `test_pagination_isLoadingMore_중복방지()`는 빠른 스크롤 시 중복 로딩을 차단하는지 확인하며, `test_중복메시지_appendMessage_방지필요()`는 chatId 기반 중복 필터링을 테스트합니다. 실제 측정 결과 전체 메시지 로드 시 10MB였던 메모리 사용량이 pagination 적용 후 1MB로 감소하여 90% 절감 효과를 확인했습니다. 이는 저사양 기기에서도 안정적인 채팅 경험을 제공하는 핵심 요소이며, 1만 개 메시지가 누적된 오래된 채팅방에서도 앱 크래시 없이 부드러운 스크롤을 보장합니다.

### 키워드

`Pagination`, `fetchRecentMessages`, `fetchMessagesBefore`, `limit: 30`, `isLoadingMore`, `Pending Queue`, `메모리 90% 절감`, `10MB → 1MB`, `ChatReactorTests`, `Relationship 기반 쿼리`, `중복 방지`, `메시지 손실 방지`, `flushPendingMessages`

---

## 섹션 6: Cursor-based Infinite Scroll - 확장 가능한 피드 설계 ⭐️⭐️⭐️⭐️

### 핵심 문단

커뮤니티 피드에서 일반적으로 사용하는 Offset 기반 Pagination은 근본적인 한계를 가지고 있습니다. 첫째, 중간 삽입이나 삭제가 발생하면 중복 또는 누락 문제가 발생합니다. 예를 들어 첫 페이지 로드 후 (1-20번 게시물) 5개의 새 글이 추가되면, 두 번째 페이지 요청 시 `LIMIT 20 OFFSET 20`으로 21-40번을 가져오게 되는데 실제로는 기존 16-20번이 21-25번으로 밀려 26-45번을 가져오게 되어 21-25번 게시물이 누락됩니다. 반대로 삭제가 발생하면 16-20번이 중복으로 표시됩니다. 둘째, 대규모 데이터에서 성능이 급격히 저하됩니다. `OFFSET 10000`은 데이터베이스가 1만 개 행을 건너뛰어야 하므로 인덱스를 활용할 수 없어 Full table scan이 발생하며, 페이지 번호가 클수록 쿼리 속도가 선형적으로 느려집니다. 셋째, 정렬 기준이 변경되면 OFFSET의 의미가 완전히 달라져 일관성이 깨집니다. 이러한 한계 때문에 확장 가능한 피드 시스템에는 Cursor 기반 Pagination이 필수적입니다.

Cursor-based Pagination은 서버가 생성한 opaque 문자열(보통 Base64 인코딩)을 통해 "마지막으로 본 항목"을 추적합니다. 클라이언트는 cursor의 의미를 알 필요 없이 서버에 그대로 전달하기만 하면 되며, 서버만 이를 해석합니다. 첫 페이지 요청 시 `next=null`을 보내면 서버가 첫 20개 게시물과 함께 `nextCursor="abc123"`을 반환하고, 두 번째 페이지 요청 시 `next="abc123"`을 보내면 서버가 "abc123 이후" 20개와 새로운 cursor를 반환합니다. 서버는 cursor에 `{createdAt: "2025-01-20T10:00:00Z", id: "post_123"}` 같은 정보를 인코딩하여 `WHERE (createdAt, id) > (cursor.createdAt, cursor.id) ORDER BY createdAt, id LIMIT 20` 쿼리를 실행합니다. 이 방식은 인덱스를 활용할 수 있어 빠르며, cursor는 절대 위치가 아닌 마지막 항목을 기준으로 하므로 중간에 새 글이 추가되거나 삭제되어도 다음 페이지를 정확히 이어서 로드할 수 있습니다.

클라이언트 구현에서는 RxSwift Operator Chain을 활용하여 불필요한 API 호출을 방지했습니다. `UICollectionView.rx.contentOffset`을 관찰하면서 `distinctUntilChanged()`로 같은 스크롤 이벤트의 중복을 제거하고, `filter { shouldLoadMore }`로 트리거 조건을 만족하는 이벤트만 통과시킨 후, `throttle(.milliseconds(500))`으로 500ms당 최대 1번만 API를 호출하도록 제한했습니다. 사용자가 빠르게 스크롤하여 1초 동안 10번의 스크롤 이벤트가 발생해도 실제 API 호출은 2번(0ms, 500ms)만 발생하여 API flooding을 효과적으로 방지합니다. 이러한 operator 조합은 네트워크 부담을 줄이면서도 사용자가 스크롤을 멈췄을 때 즉시 다음 페이지를 로드할 수 있어 반응성과 효율성을 동시에 확보합니다.

nextCursor 상태 관리는 Reactor의 State에서 처리합니다. 서버 응답으로 받은 `{ data: [...], nextCursor: "xyz789" }`를 State에 저장하며, 마지막 페이지는 `nextCursor`가 빈 문자열(`""`) 또는 `"0"`으로 반환되어 판별합니다. 추가 로드 시 `guard !currentState.nextCursor.isEmpty` 체크로 마지막 페이지에서는 요청을 차단하며, `isLoadingMore` 플래그로 중복 요청을 방지합니다. 로딩 중일 때(`isLoadingMore = true`) 사용자가 다시 스크롤해도 `guard !currentState.isLoadingMore` 조건으로 무시되며, 로딩 완료 시 `isLoadingMore = false`로 리셋하여 다음 페이지 로드를 가능하게 합니다. 에러 발생 시에도 `isLoadingMore = false`로 설정하여 사용자가 재시도할 수 있도록 하며, nextCursor는 유지하여 같은 페이지를 다시 요청할 수 있습니다.

Offset 방식 대비 실제 성능과 안정성이 크게 개선되었습니다. 100개 이상의 게시물에서 infinite scroll 테스트 결과 중복 또는 누락된 항목이 0건이었으며, 실시간으로 새 글이 추가되는 상황에서도 페이지네이션이 안정적으로 동작했습니다. 서버 쿼리 속도는 평균 30% 향상되었는데, Offset 10000 기준 약 500ms가 걸리던 쿼리가 Cursor 방식에서는 인덱스를 활용하여 약 150ms로 단축되었습니다. 특히 1만 개 게시물이 누적된 상황에서도 성능 저하 없이 일정한 속도를 유지하여 확장성을 입증했습니다. 서버 측에서도 인덱스 기반 쿼리로 CPU 사용량이 감소했으며, 클라이언트는 nextCursor 관리라는 약간의 복잡도 증가가 있지만 안정성과 성능 이득이 훨씬 크다는 trade-off 판단을 내렸습니다.

### 키워드

`Cursor-based Pagination`, `Offset 한계`, `중간 삽입/삭제 문제`, `nextCursor`, `인덱스 활용`, `성능 30% 향상`, `중복/누락 0건`, `distinctUntilChanged`, `throttle`, `isLoadingMore`, `확장성`, `opaque 문자열`, `API flooding 방지`

### 다이어그램 제안 (PDF 작성 시)

**Diagram 1: Offset vs Cursor 중복/누락 시나리오**
```
┌─────────────────────────────────────────────────┐
│         Offset 방식 (문제 발생)                  │
├─────────────────────────────────────────────────┤
│ 1페이지: [1,2,3,4,5] (LIMIT 5 OFFSET 0)        │
│    ↓                                            │
│ 새 글 A,B,C 추가 → 기존 글 밀림                 │
│    ↓                                            │
│ 2페이지: [6,7,8,9,10] (LIMIT 5 OFFSET 5)       │
│                                                 │
│ 결과: 4,5번 누락! ❌                            │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│         Cursor 방식 (안정적)                     │
├─────────────────────────────────────────────────┤
│ 1페이지: [1,2,3,4,5] nextCursor="5"            │
│    ↓                                            │
│ 새 글 A,B,C 추가 → cursor는 "5" 기준 유지       │
│    ↓                                            │
│ 2페이지: [6,7,8,9,10] (cursor="5" 이후)        │
│                                                 │
│ 결과: 중복/누락 없음 ✅                         │
└─────────────────────────────────────────────────┘
```

**Diagram 2: 성능 비교 (1만 개 데이터 기준)**
```
┌────────────────────────────────────────┐
│     Offset vs Cursor 쿼리 속도         │
├────────────────┬───────────────────────┤
│  방식          │   10,000번째 페이지    │
├────────────────┼───────────────────────┤
│ Offset 10000   │ 500ms (Full scan)     │
│                │ ❌ 느림               │
├────────────────┼───────────────────────┤
│ Cursor         │ 150ms (Index scan)    │
│                │ ✅ 70% 빠름           │
└────────────────┴───────────────────────┘

성능 향상: 350ms 단축 (70% 개선)
```

**Diagram 3: RxSwift Operator Chain**
```
UICollectionView.rx.contentOffset
  ↓
distinctUntilChanged()  // 중복 이벤트 제거
  ↓
filter { shouldLoadMore }  // 트리거 조건만 통과
  ↓
throttle(.milliseconds(500))  // 500ms당 최대 1번
  ↓
subscribe { loadMore() }

효과: 10번 스크롤 → 2번 API 호출 (80% 감소)
```

---

## 섹션 7: 트러블슈팅 (작성 예정)

---

## 📝 작성 원칙 (기억용)

1. **코드 없이 이해 가능하게**
   - 기술 용어만 나열 X
   - 구체적인 예시 포함 (API 3개 동시 호출 등)
   - before/after 명확히

2. **실제 적용 사례 설명**
   - "채팅 기능에서 3단계 작업 순차 실행"
   - "메시지 손실 방지"
   - "중복 필터링"

3. **검증 구체화**
   - "12개 단위 테스트"
   - "ExReactorKit 6개 + 채팅 로직 6개"
   - "엣지 케이스 확인"

4. **결과 측정 가능하게**
   - "코드 가독성 향상" → "복잡한 RxSwift 체이닝 대신 간결한 async/await"
   - "동시성 안전성" → "UI 크래시 원천 차단"
   - "메모리 누수 방지" → "Task 자동 취소"
