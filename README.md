# Pickfit

<img width="1151" height="449" alt="Image" src="https://github.com/user-attachments/assets/7febd115-3320-4d75-90f2-d665da034e03" />

## 앱의 기능

- 소셜 로그인
- 홈 & 스토어 탐색
- 장바구니 & 결제
- 주문 상태 추적
- 커뮤니티 피드
- 실시간 채팅

## 기술 스택

- **Architecture**: ReactorKit
- **UI**: UIKit  SnapKit
- **Reactive**: RxSwift
- **Network**: Alamofire  Socket.IO
- **Storage**: Realm  Keychain

## 고려한 사항

### ReactorKit

ReactorKit은 단방향 아키텍처를 컴파일 단계에서 강제해 상태 변화의 흐름을 명확하게 보장합니다. <br>
비동기 로직은 mutate(), 상태 변경은 reduce()에 집중되기 때문에 예측 가능한 구조를 유지할 수 있고 <br>
결과적으로 협업 시에도 일정한 품질로 코드를 유지할 수 있었습니다. <br>
또한 View와 로직이 분리되어 독립적인 단위 테스트 작성이 용이하여 도입하였습니다.

**`run` Extension**


ReactorKit은 RxSwift Observable 기반으로 설계되어 있어 concurrency를 직접 사용할 수 없는 제약이 있습니다.<br>
이를 해결하기 위해 async/await를 ReactorKit의 Observable로 브릿징하는 커스텀 레이어를 구현했습니다.

**해결 방법**

Swift Concurrency의 `Task`를 생성하여 async 작업을 실행하고<br>
 RxSwift의 `Observable.create`를 통해 Mutation을 스트림으로 변환합니다.


```swift
// Core/Utill/Extension/ExReactorKit.swift
extension Reactor {
    func run(
        operation: @escaping @MainActor @Sendable (_ send: Send<Mutation>) async throws -> Void,
        onError: @escaping (Error) -> Mutation?
    ) -> Observable<Mutation> {
        .create { observer in
            let task = Task {
                let send = Send { observer.onNext($0) }
                do {
                    try await operation(send)
                } catch {
                    if let m = onError(error) {
                        observer.onNext(m)
                    }
                }
                observer.onCompleted()
            }
            return Disposables.create { task.cancel() }
        }
    }
}

public struct Send<Mutation>: Sendable {
    let send: @Sendable (Mutation) -> Void

    public func callAsFunction(_ mutation: Mutation) {
        guard !Task.isCancelled else { return }
        self.send(mutation)
    }
}
```

**핵심 기능**
- `Task` 내부에서 `Send` 클로저로 Mutation을 캡처
- `send()` 호출 시 `observer.onNext()`로 Observable에 Mutation 전달
- `Disposables.create`로 Task 취소 자동 처리
- `@MainActor`로 메인 스레드 안전성 보장
- `Task.isCancelled`로 취소된 Task의 Mutation 무시

**실제 사용 예시 - 병렬 API 호출**:

```swift
// Presentation/Home/HomeReactor.swift
case .viewIsAppearing:
    return run { send in
        // async let으로 API 동시 호출
        async let stores = storeRepository.fetchStores(category: "Modern", ...)
        async let banners = storeRepository.fetchBanners()

        let (storesResult, bannersResponse) = try await (stores, banners)

        // 각 응답마다 개별 Mutation 배출
        send(.setStores(storesResult.stores))
        send(.setBanners(bannersResponse.data))

        // 첫 번째 스토어의 메뉴 자동 로드
        if !storesResult.stores.isEmpty {
            let storeDetail = try await storeRepository.fetchStoreDetail(
                storeId: storesResult.stores[0].storeId
            )
            send(.setMenuList(storeDetail.menuList))
        }
    }
```

**장점**:
- RxSwift Observable과 async/await의 자연스러운 통합
- Task 취소 시 자동으로 Disposable 처리
- try-catch로 명확한 에러 핸들링

---

**중복 토큰 갱신 직렬화**:

```swift
actor TokenRefreshCoordinator {
    private var isRefreshing = false
    private var waitingContinuations: [CheckedContinuation<Void, Error>] = []

    func refresh() async throws {
        // 이미 갱신 중이면 대기
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                waitingContinuations.append(continuation)
            }
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            // NetworkManager.auth 사용 (AuthInterceptor 없음 → 무한 루프 방지)
            let response = try await NetworkManager.auth.fetch(
                dto: RefreshTokenResponseDTO.self,
                router: LoginRouter.refreshToken
            )

            await AuthTokenStorage.shared.write(
                access: response.accessToken,
                refresh: response.refreshToken
            )

            // 대기 중인 모든 요청 재개
            waitingContinuations.forEach { $0.resume() }
            waitingContinuations.removeAll()
        } catch {
            // 실패 시 모든 대기 요청에게 에러 전달
            waitingContinuations.forEach { $0.resume(throwing: error) }
            waitingContinuations.removeAll()
            throw error
        }
    }
}
```

**장점**:
- Actor가 serial execution 보장 (컴파일 타임 스레드 안전성)
- 여러 API가 동시에 419 에러를 받아도 토큰 갱신은 1회만 실행
- 대기 중인 요청들은 continuation으로 일시 정지 후 재개

---

### 채팅 메시지 손실 방지 (pendingQueue)

**문제 상황**

Socket.IO로 실시간 메시지를 받을 때, 초기 로딩이 완료되기 전에 Socket 메시지가 도착하면 메시지가 손실되거나 중복될 수 있습니다.

**해결 방법**

```swift
// Presentation/Chat/ChatReactor.swift
final class ChatReactor: Reactor {
    private var isInitialLoadComplete = false
    private var pendingSocketMessages: [ChatMessageEntity] = []

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return run { send in
                // 1. CoreData 캐시 로드
                let cachedMessages = ChatStorage.shared.fetchRecentMessages(...)
                if !cachedMessages.isEmpty {
                    send(.setMessages(cachedMessages))
                }

                // 2. REST API로 최신 메시지 조회
                let messages = try await chatRepository.fetchChatHistory(...)
                send(.setMessages(messages))

                // 3. 초기 로딩 완료 → pendingQueue 플러시
                self.isInitialLoadComplete = true
                if !self.pendingSocketMessages.isEmpty {
                    send(.flushPendingMessages(self.pendingSocketMessages))
                    self.pendingSocketMessages.removeAll()
                }
            }

        case .socketMessageReceived(let message):
            // 초기 로딩 완료 전이면 큐에 저장
            if !isInitialLoadComplete {
                pendingSocketMessages.append(message)
                return .empty()
            }
            return .just(.appendMessage(message))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .appendMessage(let message):
            // chatId 기반 중복 방지
            if !newState.messages.contains(where: { $0.chatId == message.chatId }) {
                newState.messages.append(message)
            }
        case .flushPendingMessages(let messages):
            messages.forEach { message in
                if !newState.messages.contains(where: { $0.chatId == message.chatId }) {
                    newState.messages.append(message)
                }
            }
        }
        return newState
    }
}
```

**장점**:
- 초기 로딩 중 도착한 Socket 메시지를 pendingQueue에 임시 저장
- 로딩 완료 후 한 번에 플러시하여 메시지 손실 방지
- `chatId` 기반 중복 체크로 동일 메시지 방지

---

### 채팅 메시지 Pagination

채팅방에 수천 개의 메시지가 쌓이면, 한 번에 모든 메시지를 로드할 경우 메모리 부족과 UI 렌더링 지연이 발생합니다. 이를 해결하기 위해 로컬 데이터베이스에서 최근 30개씩만 로드하고, 사용자가 스크롤할 때 추가로 로드하는 pagination 전략을 구현했습니다.

```swift
// Presentation/Chat/ChatReactor.swift
case .viewDidLoad:
    return run { send in
        // 1. 로컬 DB에서 최근 30개만 로드
        let cachedMessages = ChatStorage.shared.fetchRecentMessages(
            roomId: self.roomId,
            limit: 30
        )

        if !cachedMessages.isEmpty {
            send(.setMessages(cachedMessages))  // 즉시 UI 표시
        }

        // 2. REST API로 최신 메시지 동기화
        let messages = try await chatRepository.fetchChatHistory(roomId: self.roomId)
        send(.setMessages(messages))
    }

case .loadMoreMessages:
    // 중복 로딩 방지
    guard !currentState.isLoadingMore else { return .empty() }

    return run { send in
        send(.setLoadingMore(true))

        // 가장 오래된 메시지 기준으로 이전 30개 로드
        guard let oldestMessage = currentState.messages.first else { return }

        let olderMessages = ChatStorage.shared.fetchMessagesBefore(
            roomId: self.roomId,
            beforeDate: oldestMessage.createdAt,
            limit: 30
        )

        send(.prependMessages(olderMessages))
        send(.setLoadingMore(false))
    }
```

**장점**:
- 초기 로딩 속도 개선 (전체 메시지 대신 30개만 로드)
- 메모리 사용량 최소화 (필요한 메시지만 메모리에 유지)
- 스크롤 시 추가 로드로 자연스러운 UX 제공

---

