# Architecture Deep Dive

## Overall Pattern: Layered Architecture + ReactorKit + Repository Pattern

This project follows **Layered Architecture** principles with **ReactorKit** for presentation layer and **Repository Pattern** for data access.

**Key Distinction**:
- Not "Pure" Clean Architecture (no separate UseCase layer)
- Practical Layered approach with clear separation of concerns

## Layer Responsibilities

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation Layer (UI)                                     │
│ - ViewControllers (bind UI to Reactor state)               │
│ - Views (UI layout with SnapKit)                           │
│ - Reactors (ViewModel + business logic orchestration)      │
└─────────────────────────────────────────────────────────────┘
                            ↓ Calls
┌─────────────────────────────────────────────────────────────┐
│ Core Layer (Business Logic)                                │
│ - Repositories (Data access abstraction)                   │
│ - Managers (Singleton services: Cart, Badge, Login, etc.)  │
│ - Entities (Domain models)                                 │
│ - Mappers (DTO ↔ Entity transformation)                    │
└─────────────────────────────────────────────────────────────┘
                            ↓ Calls
┌─────────────────────────────────────────────────────────────┐
│ Infrastructure Layer (Data & Network)                      │
│ - NetworkManager (Actor-based HTTP client)                 │
│ - Router (Type-safe API endpoint definition)               │
│ - DTO (API contracts, Codable)                             │
│ - Storage (CoreData, Keychain)                             │
│ - Socket (WebSocket for real-time messaging)               │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow & Lifecycle

### REST API Request/Response Flow
```
1. User Action (button tap, scroll, etc.)
   ↓
2. Reactor.Action (via RxSwift binding)
   ↓
3. Reactor.mutate() → run() for async operations
   ↓
4. Repository.fetchXXX() async throws
   ↓
5. NetworkManager.fetch(dto:router:) [Actor-isolated]
   ├─ AuthInterceptor.adapt() → Add access token to headers
   ├─ Router.asURLRequest() → Build URLRequest
   ├─ Alamofire.request() → Execute HTTP request
   └─ If 419 → AuthInterceptor.retry() → Token refresh → Retry
   ↓
6. API Response (HTTP 200-299)
   ↓
7. DTO Decoding (Codable)
   ↓
8. Mapper.toEntity() → Convert DTO to Domain Entity
   ↓
9. (Optional) Storage.save() → Persist to CoreData/Keychain
   ↓
10. Return Entity to Reactor
   ↓
11. Reactor.Mutation → Reactor.reduce()
   ↓
12. Reactor.State updated
   ↓
13. ViewController.bind() subscription fires (RxSwift)
   ↓
14. UI Update (UITableView, UILabel, etc.)
```

### Socket.IO Real-time Message Flow
```
1. Reactor connects to Socket
   ↓
2. SocketIOManager.connectDTO(to: .chat(roomId))
   ↓
3. AsyncStream<Result<DTO, Error>> yields packets
   ↓
4. For each DTO packet:
   ├─ Mapper.toEntity()
   ├─ Reactor.Mutation.appendMessage()
   ├─ CoreDataManager.saveContext() (background)
   └─ BadgeManager.incrementUnreadCount() (if needed)
   ↓
5. Reactor.State updated (messages array)
   ↓
6. UI Update via RxSwift binding
```

### Token Refresh Flow (419 Error Handling)
```
1. API Request fails with HTTP 419 (Token Expired)
   ↓
2. AuthInterceptor.retry() detects 419
   ↓
3. TokenRefreshCoordinator.refresh() (Actor prevents concurrent refreshes)
   ├─ If already refreshing → Wait for result
   └─ If not refreshing → Start refresh
   ↓
4. Call POST /auth/refresh with refreshToken
   ├─ Uses NetworkManager.auth (no interceptor to avoid recursion)
   └─ Returns new accessToken + refreshToken
   ↓
5. KeychainAuthStorage.write() → Save new tokens
   ↓
6. Resume all waiting requests with new token
   ↓
7. Retry original request (now with new accessToken)
```

---

## Core Patterns & Best Practices

### 1. Singleton Manager Pattern

| Manager | Responsibility | State Type | File Path |
|---------|---------------|------------|-----------|
| `CartManager` | Shopping cart items | `BehaviorRelay<[CartItem]>` | `Core/Manager/CartManager.swift` |
| `BadgeManager` | Unread message counts | `Dictionary<String, Int>` | `Core/Manager/BadgeManager.swift` |
| `ChatStateManager` | Active room tracking | `String` (roomId) | `Core/Manager/ChatStateManager.swift` |
| `LoginManager` | OAuth flows (Kakao/Apple) | Stateless | `Core/Manager/LoginManager.swift` |
| `IamportManager` | Payment processing | Iamport SDK wrapper | `Core/Manager/IamportManager.swift` |

```swift
// Singleton
static let shared = CartManager()

// RxSwift Observable for reactive updates
private let cartItemsRelay = BehaviorRelay<[CartItem]>(value: [])
var cartItems: Observable<[CartItem]> { cartItemsRelay.asObservable() }

// Mutate state
func addToCart(menu: StoreDetailEntity.Menu, size: String, color: String) {
    var items = cartItemsRelay.value
    items.append(CartItem(...))
    cartItemsRelay.accept(items)  // Notify all observers
}
```

### 2. Generic BaseViewController<T: BaseView> Pattern

```swift
class BaseViewController<T: BaseView>: UIViewController {
    let mainView = T()  // Generic view automatically instantiated

    override func loadView() {
        self.view = mainView  // Replace root view
    }

    func bind() {
        // Override in subclasses for Reactor bindings
    }
}

// Usage
class ChatViewController: BaseViewController<ChatView> {
    override func bind() {
        reactor.state.map { $0.messages }
            .bind(to: mainView.tableView.rx.items)
            .disposed(by: disposeBag)
    }
}
```

### 3. UIConfigure Three-Phase Lifecycle

```swift
protocol UIConfigure {
    func configureHierarchy()  // 1. Add subviews
    func configureLayout()     // 2. Set constraints (SnapKit)
    func configureUI()         // 3. Apply styling
}

// BaseView calls these in order
init() {
    super.init(frame: .zero)
    configureHierarchy()
    configureLayout()
    configureUI()
}
```

### 4. Repository + Mapper Pattern

```swift
final class ChatRepository {
    func fetchChatHistory(roomId: String, next: String? = nil) async throws -> [ChatMessageEntity] {
        // 1. Fetch from API
        let dto = try await NetworkManager.shared.fetch(
            dto: ChatHistoryResponseDTO.self,
            router: ChatRouter.fetchChatHistory(roomId: roomId, next: next)
        )

        // 2. Map DTO → Entity
        let currentUserId = KeychainAuthStorage.shared.readUserIdSync() ?? ""
        let entities = ChatMessageMapper.toEntities(dto.data, currentUserId: currentUserId)

        // 3. Persist in background
        Task { await ChatStorage.shared.saveMessages(entities) }

        // 4. Return domain entities
        return entities
    }
}
```

### 5. Actor-based Concurrency

```swift
actor NetworkManager {
    static let shared = NetworkManager(hasInterceptor: true)   // With auth
    static let auth = NetworkManager(hasInterceptor: false)    // Without auth (for refresh)

    func fetch<T: DTO, R: Router>(dto: T.Type, router: R) async throws -> T {
        // Actor ensures serial access, no data races
    }
}

actor KeychainAuthStorage: AuthTokenStorage {
    // Actor-isolated methods (async)
    func readAccess() async -> String?

    // nonisolated for sync access (e.g., from AuthInterceptor)
    nonisolated func readAccessSync() -> String?
}
```

### 6. Async/Await + RxSwift Integration

```swift
// Defined in ExReactorKit.swift
func run(
    operation: @Sendable @escaping (SendFunction) async throws -> Void,
    onError: @escaping (Error) -> Mutation
) -> Observable<Mutation>

// Usage in Reactor
case .viewDidLoad:
    return run(
        operation: { send in
            async let stores = storeRepository.fetchStores(...)
            async let banners = storeRepository.fetchBanners()
            let (s, b) = try await (stores, banners)

            send(.setStores(s))
            send(.setBanners(b))
        },
        onError: { error in
            return .setError(error)
        }
    )
```

---

## Architectural Trade-offs

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **ReactorKit** instead of MVVM | Enforces unidirectional data flow | Learning curve, boilerplate |
| **Repository Pattern** without protocols | Simpler, less boilerplate | Harder to mock in tests |
| **Actor for NetworkManager** | Compile-time thread safety | All methods must be async |
| **Singleton Managers** | Shared state, easy access | Global mutable state |
| **CoreData + CloudKit** | Free iCloud sync | Complexity, relationship pitfalls |
| **Keychain for tokens** | Secure, persists across reinstalls | Async access needed |
| **BadgeManager in-memory** | Fast read/write | Lost on app restart |
