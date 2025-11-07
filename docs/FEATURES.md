# Feature Implementation Details

## Feature Overview

| # | Feature | Reactors | Key Files |
|---|---------|----------|-----------|
| 1 | Authentication & Login | `LoginReactor` | LoginManager, AuthRepository, AuthInterceptor |
| 2 | Chat System | `ChatReactor`, `ChatListReactor` | SocketIOManager, BadgeManager, ChatStorage |
| 3 | Home & Store Discovery | `HomeReactor`, `StoreListReactor`, `StoreDetailReactor` | StoreRepository, CompositionalLayout |
| 4 | Shopping Cart & Checkout | `ShoppingCartReactor`, `ProductDetailReactor` | CartManager, IamportManager |
| 5 | Order History | `OrderHistoryReactor` | OrderRepository, OrderStatusEntity |
| 6 | Community & Posts | `CommunityReactor` | PostRepository, PinterestLayout |
| 7 | Image Loading | - | ImageLoadView (18 screens) |

---

## 1. Authentication & Login

### Files
- `Presentation/Login/LoginReactor.swift`
- `Core/Manager/LoginManager.swift`
- `Core/Domain/Repository/AuthRepository.swift`
- `Core/Storage/AuthTokenStorage.swift`
- `Core/Network/Interceptor/AuthInterceptor.swift`
- `Core/Network/Interceptor/TokenRefreshCoordinator.swift`

### Key Design Decisions

**1. Actor-based KeychainAuthStorage**
- Keychain is not thread-safe, Actor ensures serial access
- `nonisolated func readAccessSync()` for AuthInterceptor compatibility

**2. Dual NetworkManager Instances**
- `NetworkManager.shared` (with AuthInterceptor) - normal requests
- `NetworkManager.auth` (no AuthInterceptor) - login & refresh APIs
- Prevents infinite loop during token refresh

**3. TokenRefreshCoordinator Pattern**
- Multiple concurrent 419 errors → only 1 refresh call
- Actor-based serialization with waiting continuations

**4. Error Codes**
| Code | Meaning | Action |
|------|---------|--------|
| 419 | Access token expired | Auto refresh + retry |
| 401/403 | Unauthorized | Clear tokens, goto login |
| 418 | Refresh token expired | Clear tokens, goto login |

---

## 2. Chat Badge & Unread Message System

### Files
- `Core/Manager/BadgeManager.swift`
- `Core/Storage/ChatRoomStorage.swift`
- `Core/Storage/ChatStorage.swift`
- `Presentation/ChatList/ChatListCell.swift`
- `Presentation/Chat/ChatReactor.swift`

### Architecture

**CoreData Relationship**:
```
ChatRoom (1) ←→ (N) Message
├─ roomId: String
├─ lastReadChatId: String?
└─ messages: NSSet?
```

**BadgeManager** (In-memory):
- `Dictionary<String, Int>` for real-time badge counts
- Fast read access for UI updates

**Two-Phase Unread Count**:
1. Initial Load: API call for accurate count
2. Push Notification: Just increment BadgeManager (no API)

**Socket + Push Duplicate Prevention**:
- Only increment badge on Push notifications
- Ignore Socket messages for badge (prevents +2 bug)

---

## 3. Home & Store Discovery

### Files
- `Presentation/Home/HomeReactor.swift`
- `Presentation/Home/HomeViewController.swift`
- `Presentation/StoreList/StoreListReactor.swift`
- `Presentation/StoreDetail/StoreDetailReactor.swift`

### Architecture

**UICollectionViewCompositionalLayout** for 5 sections:
1. Main Store Carousel (horizontal paging)
2. Category Grid (8 icons)
3. Banner Carousel
4. Brand Logos (horizontal scroll)
5. Product Grid (2-column)

**Parallel API Calls**:
```swift
async let stores = storeRepository.fetchStores(...)
async let banners = storeRepository.fetchBanners()
let (s, b) = try await (stores, banners)
```

### Known Limitations
- Pagination not implemented (nextCursor received but unused)
- Hardcoded location (127.0, 37.5)
- Hardcoded category "Modern" on home

---

## 4. Shopping Cart & Checkout

### Files
- `Core/Manager/CartManager.swift`
- `Presentation/ShoppingCart/ShoppingCartReactor.swift`
- `Presentation/ShoppingCart/ShoppingCartViewController.swift`

### Architecture

**CartManager Singleton + BehaviorRelay**:
- Global cart state across all screens
- All screens subscribe via `CartManager.shared.cartItems`

**Three-Step Checkout**:
1. Create Order API → Returns orderCode
2. Execute Payment (Iamport SDK)
3. Validate Payment API

### Known Limitations
- No persistence (cart lost on app restart)
- Color ignored in duplicate check
- No quantity limits
- Mixed store items allowed

---

## 5. Order History & Status Tracking

### Files
- `Presentation/OrderHistory/OrderHistoryReactor.swift`
- `Presentation/OrderHistory/OrderHistoryViewController.swift`
- `Core/Domain/Entity/OrderHistoryEntity.swift`

### Order Status Flow
```
PENDING_APPROVAL → APPROVED → IN_PROGRESS → READY_FOR_PICKUP → PICKED_UP
```

### Architecture
- Section-based UI (Banner, Ongoing, History)
- Timeline-based status tracking with timestamps
- Pull-to-refresh (manual, no auto-polling)

---

## 6. Community & Posts (Cursor-based Infinite Scroll)

### Files
- `Presentation/Community/CommunityReactor.swift`
- `Presentation/Community/CommunityViewController.swift`
- `Presentation/Community/PinterestLayout.swift`

### Key Design: Cursor-based Pagination

**Why Cursor > Offset**:
| Aspect | Offset | Cursor |
|--------|--------|--------|
| Mid-list changes | Duplicates/missing | Consistent |
| Scalability | OFFSET slow | Indexed queries |

**Infinite Scroll Trigger** (200pt pre-load):
```swift
mainView.collectionView.rx.contentOffset
    .map { shouldLoadMore(offset: $0) }
    .distinctUntilChanged()  // Prevent duplicates
    .filter { $0 }           // Only when true
    .throttle(.milliseconds(500))  // Max 1 per 500ms
    .subscribe(onNext: { _ in
        reactor.action.onNext(.loadMore)
    })
```

**Loading State Separation**:
- `isLoading`: Full-screen spinner (initial load)
- `isLoadingMore`: Bottom spinner (pagination)

---

## 7. Image Caching Policy & Memory Optimization

### Files
- `Presentation/Base/ImageLoadView.swift` - Used in 18 screens

### Caching Strategy Enum

```swift
enum ImageCachingStrategy {
    case diskAndMemory  // Products, profiles (high reuse)
    case memoryOnly     // Chat images (one-time, high volume)
    case none           // QR codes, coupons (real-time)
}
```

### Key Features

**DownsamplingImageProcessor**:
- 4000×3000 → 390×400 (88% memory reduction)
- Decodes at smaller size, not scale after load

**419 Token Handling**:
- Kingfisher doesn't use AuthInterceptor
- ImageLoadView detects 419 → TokenRefreshCoordinator → retry

**Fallback Strategy**:
1. Try downsampling
2. If fails → retry with original size
3. If fails → placeholder icon

---

## Known Issues & Solutions

### CoreData Relationship Configuration
- **Issue**: Editing xcdatamodeld XML directly causes Xcode crash
- **Solution**: Always use Xcode Data Model Editor GUI

### CoreData Manual Codegen
- **Issue**: "Multiple commands produce" error
- **Solution**: Set Codegen to "Manual/None" in Xcode Inspector

### Socket + Push Duplicate Messages
- **Issue**: Badge +2 instead of +1
- **Solution**: Only increment on Push, ignore Socket for badges

### Concurrent Token Refresh
- **Issue**: N concurrent 419 → N refresh calls
- **Solution**: TokenRefreshCoordinator actor serializes requests
