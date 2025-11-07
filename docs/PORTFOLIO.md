# Portfolio Highlights

포트폴리오에 강조할 주요 기술적 설계 결정과 테스트 전략입니다.

---

## 1. ReactorKit + Async/Await Integration with Test Code

### Files
- `Core/Extension/ExReactorKit.swift` - Custom `run()` extension
- `PickfitTests/ExReactorKitTests.swift` - 6 test cases
- `PickfitTests/ChatReactorTests.swift` - 6 test cases
- `PickfitTests/TestFixtures.swift` - Mock data
- `PickfitTests/MockChatRepository.swift` - Mock repository

### Why ReactorKit?

**Problem**: UIViewController가 너무 많은 책임 (View + Business + Network)

**Solution**: ReactorKit으로 관심사 분리
- **View**: UI 업데이트만 (State → UI binding)
- **Reactor**: Business Logic + State Management
- **Unidirectional Data Flow**: Action → Mutation → State

### ExReactorKit: Async/Await Integration

**Problem**: ReactorKit은 RxSwift 기반 → async/await 직접 사용 불가

**Solution**: Custom `run()` extension

```swift
extension Reactor {
    func run(
        operation: @Sendable @escaping (SendFunction) async throws -> Void,
        onError: @escaping (Error) -> Mutation
    ) -> Observable<Mutation> {
        return Observable.create { observer in
            let task = Task { @MainActor in
                let send = SendFunction { mutation in
                    guard !Task.isCancelled else { return }
                    observer.onNext(mutation)
                }

                do {
                    try await operation(send)
                } catch {
                    observer.onNext(onError(error))
                }
            }

            return Disposables.create { task.cancel() }
        }
    }
}
```

**Benefits**:
- async/await을 Reactor에서 자연스럽게 사용
- send()로 여러 Mutation 순차 전송
- Task 취소 자동 처리 (DisposeBag 연동)
- MainActor 보장 (UI 안전)

### Test Strategy: ExReactorKit Unit Tests

**6개 테스트 케이스** (`ExReactorKitTests.swift`):

1. `test_run_기본동작_Mutation이_Observable로_변환됨`
2. `test_run_여러_Mutation_순차적으로_전달됨`
3. `test_run_에러_발생시_onError_Mutation_방출됨`
4. `test_Reactor_해제시_Task_취소됨`
5. `test_operation_MainActor에서_실행됨`
6. `test_Send_구조체_Task_취소시_Mutation_무시`

---

## 2. ChatReactor: Real-World Business Logic Tests

### 핵심 문제 1: pendingSocketMessages 큐

**문제 상황**:
```
채팅방 진입 (viewDidLoad)
  ↓
동시 작업:
  1. Socket 연결 (즉시) → 새 메시지 수신
  2. CoreData/API 로딩 (1-2초 소요)

Socket이 먼저 메시지 받으면?
  → pendingSocketMessages 큐에 임시 저장!
```

**없었다면?**
- CoreData 로딩 중 Socket 메시지 → appendMessage
- CoreData 완료 → setMessages (덮어씌움)
- **Socket 메시지 사라짐!**

### 핵심 문제 2: 1만 개 메시지 대응 (Pagination)

```swift
// 초기: 최근 30개만
let cachedMessages = ChatStorage.shared.fetchRecentMessages(roomId: roomId, limit: 30)

// 스크롤 위로 → 이전 30개씩
let messages = ChatStorage.shared.fetchMessagesBefore(
    roomId: roomId,
    beforeDate: oldestMessage.createdAt,
    limit: 30
)
```

### 핵심 문제 3: 중복 메시지 방지

```swift
case .appendMessage(let message):
    if !newState.messages.contains(where: { $0.chatId == message.chatId }) {
        newState.messages.append(message)
    }
```

### ChatReactor 테스트 케이스

1. `test_pendingQueue_초기로딩중_소켓메시지_큐에저장`
2. `test_pendingQueue_초기로딩완료후_큐플러시`
3. `test_pagination_초기로딩_30개만`
4. `test_pagination_isLoadingMore_중복방지`
5. `test_중복메시지_appendMessage_방지필요`
6. `test_deinit_소켓연결해제`

### 포트폴리오 가치

- **테스트 코드는 시니어 개발자 필수 역량**
- Edge Case 고려 (큐, 중복, 메모리)
- 비즈니스 로직 검증 (1만 개 메시지 대응)
- 아키텍처 이해도 증명 (ExReactorKit 설계)

---

## 3. Token Refresh Coordination (Actor Pattern)

### Problem
Multiple concurrent API requests fail with 419 → all try to refresh → N refresh calls

### Solution: TokenRefreshCoordinator Actor

```swift
actor TokenRefreshCoordinator {
    private var isRefreshing = false
    private var waitingRequests: [CheckedContinuation<String, Error>] = []

    func refresh(using refreshLogic: ...) async throws -> String {
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                waitingRequests.append(continuation)
            }
        }

        isRefreshing = true
        let newToken = try await refreshLogic()

        waitingRequests.forEach { $0.resume(returning: newToken) }
        waitingRequests.removeAll()

        return newToken
    }
}
```

### Benefits
- 동시 419 → 1번만 갱신
- 나머지 요청은 대기 후 새 토큰으로 재시도
- Actor로 thread-safe

---

## 4. Image Caching Strategy

### Problem
- 상품 이미지: 재사용 빈도 높음
- 채팅 이미지: 일회성, 대량 발생
- 모두 디스크 캐시? → 용량 낭비

### Solution: 3가지 전략 Enum

```swift
enum ImageCachingStrategy {
    case diskAndMemory  // 상품, 프로필 (재사용)
    case memoryOnly     // 채팅 (일회성)
    case none           // QR, 쿠폰 (실시간)
}
```

### DownsamplingImageProcessor
- 4000×3000 → 390×400
- **메모리 88% 절감**
- 디코딩 단계에서 축소 (scale과 다름)

### 419 토큰 만료 자동 처리
- Kingfisher는 AuthInterceptor 안 거침
- ImageLoadView에서 419 감지 → TokenRefreshCoordinator → 재시도

---

## 5. Cursor-based Infinite Scroll

### Why Cursor > Offset?

| Aspect | Offset | Cursor |
|--------|--------|--------|
| 중간 삽입/삭제 | 중복/누락 | 일관성 |
| 확장성 | OFFSET 느림 | 인덱스 쿼리 |

### RxSwift Operator Chain

```swift
mainView.collectionView.rx.contentOffset
    .map { shouldLoadMore(offset: $0) }
    .distinctUntilChanged()       // 중복 방지
    .filter { $0 }                // true만 통과
    .throttle(.milliseconds(500)) // 500ms당 1회
    .subscribe(onNext: { _ in
        reactor.action.onNext(.loadMore)
    })
```

### Loading State 분리
- `isLoading`: 전체 화면 로딩 (초기)
- `isLoadingMore`: 하단 스피너 (페이지네이션)

---

## 6. CoreData Relationship Design

### ChatRoom ↔ Message 관계형 모델링

```
ChatRoom (1) ←→ (N) Message
├─ roomId: String
├─ lastReadChatId: String?
└─ messages: NSSet?
```

### Known Issue & Solution
- xcdatamodeld XML 직접 편집 → Xcode 크래시
- **항상 Xcode GUI로 관계 설정**

---

## Architecture Quality Summary

| Feature | Quality | Notes |
|---------|---------|-------|
| ReactorKit + Async/Await | 9/10 | Custom run() extension |
| Token Refresh | 9/10 | Actor-based coordination |
| Image Caching | 9/10 | Strategy pattern, 88% memory saving |
| Chat Badge System | 8/10 | Well-designed, missing restoration |
| Infinite Scroll | 8/10 | Cursor pagination |
| Shopping Cart | 6/10 | No persistence, color bug |
