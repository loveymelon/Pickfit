# 면접 준비 가이드

포트폴리오에 작성한 기능별 **구현 방법**과 **고려사항**을 정리한 문서입니다.
면접에서 "어떻게 구현했나요?", "왜 그렇게 했나요?" 질문에 대비하세요.

---

## 목차
1. [Splash & 로그인](#1-splash--로그인)
2. [회원가입](#2-회원가입)
3. [홈 화면](#3-홈-화면)
4. [커뮤니티](#4-커뮤니티)
5. [채팅](#5-채팅)
6. [미디어 뷰어](#6-미디어-뷰어)
7. [장바구니 & 결제](#7-장바구니--결제)
8. [기타](#8-기타)

---

## 1. Splash & 로그인

### 1.1 Lottie Splash 애니메이션

**구현 방법**:
```swift
// SplashViewController.swift
let animationView = LottieAnimationView(name: "splash_animation")
animationView.loopMode = .playOnce
animationView.play { [weak self] finished in
    if finished {
        self?.checkLoginStatus()  // 애니메이션 완료 후 로그인 상태 확인
    }
}
```

**고려사항**:
- 애니메이션 완료 후 로그인 상태에 따라 분기 (토큰 존재 → 메인, 없음 → 로그인)
- `loopMode = .playOnce`로 한 번만 재생
- Lottie JSON 파일은 디자이너와 협업하여 용량 최적화 (1MB 이하 권장)

**예상 꼬리 질문**:
- Q: "Lottie 대신 다른 방법은?"
- A: "UIView 애니메이션, GIF 등이 있지만, Lottie는 벡터 기반이라 해상도 무관하고 디자이너가 After Effects로 제작한 것을 그대로 사용 가능"

---

### 1.2 이메일 및 소셜 로그인 (JWT + Actor)

**구현 방법**:
```swift
// 1. 소셜 로그인 (카카오 예시)
func kakaoLogin() async throws -> String {
    if UserApi.isKakaoTalkLoginAvailable() {
        return try await loginWithApp()   // 카카오톡 앱
    } else {
        return try await loginWithAccount()  // 웹 브라우저
    }
}

// 2. 서버 로그인 API 호출
let response = try await authRepository.login(oauthToken: kakaoToken)

// 3. Keychain에 토큰 저장 (Actor로 동시성 안전)
await KeychainAuthStorage.shared.write(
    access: response.accessToken,
    refresh: response.refreshToken
)
```

**Actor 사용 이유**:
```swift
actor KeychainAuthStorage {
    func write(access: String, refresh: String) async {
        keychain.set(access, forKey: "accessToken")
        keychain.set(refresh, forKey: "refreshToken")
    }

    func readAccess() async -> String? {
        return keychain.get("accessToken")
    }
}
```

**고려사항**:
1. **Keychain 선택 이유**: UserDefaults는 암호화 안 됨, Keychain은 iOS가 암호화
2. **Actor 선택 이유**: Keychain은 thread-safe 하지 않음 → 동시 접근 시 crash 가능
3. **카카오 Fallback**: 앱 미설치 시 웹 로그인으로 자동 전환 → UX 향상

**예상 꼬리 질문**:
- Q: "Actor 대신 DispatchQueue나 Lock 안 썼나요?"
- A: "Actor는 컴파일 타임에 data race를 방지해서 런타임 오류를 원천 차단. Lock은 실수로 빼먹을 수 있음"

- Q: "토큰 갱신은 어떻게 했나요?"
- A: "AuthInterceptor에서 419 에러 감지 → TokenRefreshCoordinator가 갱신 → 원래 요청 재시도. 동시 419 발생 시 한 번만 갱신되도록 Actor로 조율"

---

## 2. 회원가입

### 2.1 정규표현식 검증 + 실시간 피드백

**구현 방법**:
```swift
// SignUpReactor.swift
func validateEmail(_ email: String) -> Bool {
    let pattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    return email.range(of: pattern, options: .regularExpression) != nil
}

func validatePassword(_ password: String) -> PasswordValidation {
    let hasMinLength = password.count >= 8
    let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
    let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
    let hasSpecialChar = password.range(of: "[!@#$%^&*]", options: .regularExpression) != nil

    return PasswordValidation(
        isLengthValid: hasMinLength,
        hasUppercase: hasUppercase,
        hasNumber: hasNumber,
        hasSpecialChar: hasSpecialChar
    )
}
```

**ReactorKit State 기반 버튼 활성화**:
```swift
// State
struct State {
    var isEmailValid: Bool = false
    var isPasswordValid: Bool = false
    var isNicknameValid: Bool = false

    var canSubmit: Bool {
        return isEmailValid && isPasswordValid && isNicknameValid
    }
}

// ViewController - bind()
reactor.state.map { $0.canSubmit }
    .bind(to: submitButton.rx.isEnabled)
    .disposed(by: disposeBag)

reactor.state.map { $0.canSubmit ? UIColor.primary : UIColor.gray }
    .bind(to: submitButton.rx.backgroundColor)
    .disposed(by: disposeBag)
```

**고려사항**:
1. **실시간 검증**: 입력할 때마다 검증 → 즉각적 피드백 (색상, 메시지)
2. **버튼 활성화**: 모든 조건 충족 시에만 가입 버튼 활성화 → 불필요한 API 호출 방지
3. **UX**: 유효하면 초록색, 무효하면 빨간색 + 구체적 메시지 ("특수문자를 포함해주세요")

**예상 꼬리 질문**:
- Q: "서버 검증도 하나요?"
- A: "네, 클라이언트 검증은 UX용이고, 서버에서도 동일하게 검증합니다. 보안상 서버 검증이 필수입니다"

---

## 3. 홈 화면

### 3.1 자동 스크롤 배너

**구현 방법**:
```swift
// HomeViewController.swift
private var autoScrollTimer: Timer?

func startAutoScroll() {
    autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
        self?.scrollToNextBanner()
    }
}

func stopAutoScroll() {
    autoScrollTimer?.invalidate()
    autoScrollTimer = nil
}

// 수동 스크롤 감지
func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    stopAutoScroll()  // 수동 스크롤 시 자동 스크롤 중지
}

func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    startAutoScroll()  // 수동 스크롤 종료 후 재시작
}
```

**고려사항**:
1. **수동 스크롤 시 일시 정지**: 사용자가 직접 넘기는데 자동으로 넘어가면 UX 저하
2. **Timer invalidate**: 화면 이탈 시 타이머 정리 → 메모리 누수 방지
3. **[weak self]**: Timer 클로저에서 강한 참조 방지

**예상 꼬리 질문**:
- Q: "화면 벗어났을 때 처리는?"
- A: "viewWillDisappear에서 stopAutoScroll() 호출, viewWillAppear에서 startAutoScroll() 호출"

---

### 3.2 CompositionalLayout 섹션 구성

**구현 방법**:
```swift
func createLayout() -> UICollectionViewLayout {
    return UICollectionViewCompositionalLayout { sectionIndex, _ in
        switch sectionIndex {
        case 0: return self.createCarouselSection()   // 메인 캐러셀
        case 1: return self.createCategorySection()   // 카테고리
        case 2: return self.createBannerSection()     // 배너
        case 3: return self.createProductGridSection() // 상품 2열
        default: return nil
        }
    }
}

func createCarouselSection() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                           heightDimension: .absolute(200))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.orthogonalScrollingBehavior = .groupPaging  // 페이징
    return section
}
```

**고려사항**:
1. **단일 CollectionView**: Nested CollectionView 대신 하나로 구성 → 성능 향상
2. **orthogonalScrollingBehavior**: 섹션별 가로/세로 스크롤 독립 설정
3. **fractional vs absolute**: 반응형 레이아웃 (fractional) vs 고정 크기 (absolute)

**예상 꼬리 질문**:
- Q: "기존 FlowLayout 대비 장점은?"
- A: "섹션별로 다른 레이아웃 적용 가능, orthogonal 스크롤 지원, 더 선언적인 코드"

---

### 3.3 스크롤 기반 네비게이션 바 전환

**구현 방법**:
```swift
func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let offset = scrollView.contentOffset.y
    let threshold: CGFloat = 100  // 전환 기준점

    // 0~1 사이 값으로 변환
    let alpha = min(1, max(0, offset / threshold))

    // 네비게이션 바 배경 투명도
    navigationController?.navigationBar.backgroundColor = UIColor.white.withAlphaComponent(alpha)

    // 타이틀 표시/숨김
    navigationItem.title = alpha > 0.5 ? "가게명" : nil
}
```

**고려사항**:
1. **점진적 전환**: 0/1 이진 전환이 아닌 alpha 값으로 부드러운 전환
2. **threshold 설정**: 헤더 이미지 높이 고려하여 적절한 시점에 전환
3. **타이틀 시점**: 배경이 어느 정도 불투명해진 후 타이틀 표시 (0.5 기준)

---

## 4. 커뮤니티

### 4.1 동영상 썸네일 추출

**구현 방법**:
```swift
// VideoThumbnailGenerator.swift
func generateThumbnail(from url: URL) async -> UIImage? {
    let asset = AVAsset(url: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true  // 회전 보정

    let time = CMTime(seconds: 0, preferredTimescale: 1)  // 첫 프레임

    do {
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cgImage)
    } catch {
        print("썸네일 생성 실패: \(error)")
        return nil
    }
}
```

**고려사항**:
1. **비동기 처리**: 썸네일 추출은 무거운 작업 → async로 메인 스레드 블로킹 방지
2. **회전 보정**: `appliesPreferredTrackTransform = true` 안 하면 가로 영상이 세로로 표시
3. **첫 프레임**: CMTime(seconds: 0)으로 첫 프레임 추출 (대표 이미지)

**예상 꼬리 질문**:
- Q: "썸네일 캐싱은?"
- A: "Kingfisher의 ImageCache를 활용하거나, URL을 키로 하는 NSCache 사용 가능"

---

### 4.2 사진/동영상 업로드 (리사이징 & 압축)

**구현 방법**:
```swift
// 이미지 리사이징 + JPEG 압축
func compressImage(_ image: UIImage, maxSize: CGFloat = 1024) -> Data? {
    let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
    let newSize = CGSize(width: image.size.width * ratio,
                         height: image.size.height * ratio)

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return resizedImage?.jpegData(compressionQuality: 0.7)  // 70% 품질
}

// 동영상 압축
func compressVideo(inputURL: URL) async throws -> URL {
    let asset = AVAsset(url: inputURL)

    guard let exportSession = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPresetMediumQuality  // 중간 품질
    ) else { throw VideoError.exportFailed }

    let outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString + ".mp4")

    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4

    await exportSession.export()

    return outputURL
}

// MultipartFormData 업로드
func uploadFiles(images: [Data], videos: [URL]) async throws {
    let formData = MultipartFormData()

    for (index, imageData) in images.enumerated() {
        formData.append(imageData,
                       withName: "files",
                       fileName: "image\(index).jpg",
                       mimeType: "image/jpeg")
    }

    for (index, videoURL) in videos.enumerated() {
        let videoData = try Data(contentsOf: videoURL)
        formData.append(videoData,
                       withName: "files",
                       fileName: "video\(index).mp4",
                       mimeType: "video/mp4")
    }

    // Alamofire upload
}
```

**고려사항**:
1. **이미지 리사이징**: 원본 4000px → 1024px로 축소 → 용량 대폭 감소
2. **JPEG 품질 70%**: 육안 차이 거의 없으면서 용량 30% 추가 절감
3. **동영상 MediumQuality**: 1080p → 720p 수준으로 자동 변환
4. **임시 파일 정리**: 업로드 완료 후 임시 파일 삭제

**예상 꼬리 질문**:
- Q: "업로드 진행률 표시는?"
- A: "Alamofire의 uploadProgress 클로저로 진행률 받아서 ProgressView에 반영"

---

### 4.3 커서 기반 페이지네이션

**구현 방법**:
```swift
// CommunityReactor.swift
struct State {
    var posts: [PostEntity] = []
    var nextCursor: String? = nil  // 서버에서 받은 커서
    var isLoadingMore: Bool = false
}

case .loadMore:
    // 중복 방지
    guard !currentState.isLoadingMore,
          let cursor = currentState.nextCursor,
          !cursor.isEmpty else {
        return .empty()
    }

    return run(
        operation: { send in
            send(.setLoadingMore(true))

            let response = try await postRepository.fetchPosts(cursor: cursor)

            send(.appendPosts(response.posts))
            send(.setNextCursor(response.nextCursor))
            send(.setLoadingMore(false))
        },
        onError: { _ in .setLoadingMore(false) }
    )
```

**Offset vs Cursor 비교**:
```
[Offset 방식의 문제]
1. 첫 페이지: offset=0, limit=20 → 게시글 1~20
2. 새 게시글 5개 추가됨
3. 두 번째 페이지: offset=20, limit=20 → 게시글 26~45
   → 21~25 누락!

[Cursor 방식의 해결]
1. 첫 페이지: cursor=null → 게시글 A~T, nextCursor="T_id"
2. 새 게시글 추가되어도 상관없음
3. 두 번째 페이지: cursor="T_id" → T 이후 게시글만 조회
   → 누락 없음!
```

**고려사항**:
1. **중복 방지 플래그**: `isLoadingMore`로 동시 요청 차단
2. **빈 커서 체크**: 마지막 페이지면 더 이상 요청 안 함
3. **커서 기반 선택 이유**: 실시간 게시글 추가가 빈번한 SNS 특성상 offset은 부적합

---

### 4.4 댓글 & 대댓글

**구현 방법**:
```swift
// 댓글 데이터 구조
struct Comment {
    let id: String
    let content: String
    let parentId: String?  // nil이면 원댓글, 있으면 대댓글
    let author: User
    let replies: [Comment]  // 대댓글 목록
}

// "답글 달기" 탭 시
func onReplyTap(to comment: Comment) {
    reactor.action.onNext(.setReplyTarget(comment))
}

// State
var replyTarget: Comment?  // 답글 대상 댓글

// View - 입력창 상단에 표시
reactor.state.map { $0.replyTarget }
    .bind { [weak self] target in
        if let target = target {
            self?.replyIndicatorLabel.text = "@\(target.author.nickname)에게 답글"
            self?.replyIndicatorView.isHidden = false
        } else {
            self?.replyIndicatorView.isHidden = true
        }
    }

// 댓글 삭제 시 대댓글도 함께 삭제 (서버에서 처리)
// 클라이언트는 삭제 API 호출 후 목록 새로고침
```

**고려사항**:
1. **parentId로 관계 표현**: 원댓글은 parentId = nil, 대댓글은 parentId = 원댓글 ID
2. **입력 UI 전환**: 답글 모드일 때 "@닉네임에게 답글" 표시 → 사용자가 현재 상태 인지
3. **계단식 삭제**: 원댓글 삭제 시 하위 대댓글도 서버에서 cascade 삭제

---

## 5. 채팅

### 5.1 채팅 진입 플로우

**구현 방법**:
```swift
// CommunityDetailViewController.swift
// 프로필 탭 → 바텀시트 → "채팅 보내기"
alertController.addAction(UIAlertAction(title: "채팅보내기", style: .default) { [weak self] _ in
    self?.reactor.action.onNext(.startChat)
})

// CommunityDetailReactor.swift
case .startChat:
    return run(operation: { [weak self] send in
        guard let authorId = self?.currentState.spotDetail?.authorId else { return }

        // 서버가 알아서 기존 방 조회 또는 새로 생성
        let roomInfo = try await chatRepository.createOrFetchChatRoom(opponentId: authorId)

        send(.setCreatedChatRoomInfo(
            roomId: roomInfo.roomId,
            nickname: roomInfo.nickname,
            profileImage: roomInfo.profileImage
        ))
    }, onError: { _ in .setError("채팅방 생성 실패") })

// ViewController에서 ChatVC로 이동
reactor.state.map { $0.createdChatRoomInfo }
    .compactMap { $0 }
    .subscribe(onNext: { [weak self] roomInfo in
        let chatVC = ChatViewController(roomInfo: roomInfo)
        self?.navigationController?.pushViewController(chatVC, animated: true)
    })
```

**고려사항**:
1. **서버 위임**: 클라이언트는 "이 사람과 채팅" API만 호출, 기존 방 존재 여부는 서버가 판단
2. **단일 API**: createOrFetch 패턴으로 분기 로직 단순화
3. **State 기반 화면 전환**: createdChatRoomInfo가 설정되면 자동으로 ChatVC 이동

---

### 5.2 Socket.IO 실시간 메시지

**구현 방법**:
```swift
// SocketIOManager.swift
class SocketIOManager {
    private var manager: SocketManager?
    private var socket: SocketIOClient?

    func connect(roomId: String) -> AsyncStream<ChatMessageEntity> {
        return AsyncStream { continuation in
            socket = manager?.socket(forNamespace: "/chat")

            socket?.on("message") { [weak self] data, _ in
                if let messageDTO = self?.parseMessage(data) {
                    let entity = ChatMessageMapper.toEntity(messageDTO)
                    continuation.yield(entity)
                }
            }

            socket?.connect()
            socket?.emit("join", ["roomId": roomId])

            continuation.onTermination = { [weak self] _ in
                self?.socket?.emit("leave", ["roomId": roomId])
                self?.socket?.disconnect()
            }
        }
    }
}

// ChatReactor.swift
func connectSocket() -> Observable<Mutation> {
    return Observable.create { [weak self] observer in
        guard let self = self else { return Disposables.create() }

        let task = Task {
            for await message in self.socketManager.connect(roomId: self.roomId) {
                observer.onNext(.appendMessage(message))
            }
        }

        return Disposables.create { task.cancel() }
    }
}
```

**고려사항**:
1. **네임스페이스**: `/chat` 네임스페이스로 채팅 전용 연결
2. **join/leave 이벤트**: 방 입장/퇴장 시 서버에 알림
3. **AsyncStream**: RxSwift와 async/await 브릿지
4. **onTermination**: 화면 이탈 시 자동 disconnect

---

### 5.3 메시지 전송 (REST API 방식)

**구현 방법**:
```swift
// Socket 대신 REST API로 전송
case .sendMessage(let content):
    return run(
        operation: { [weak self] send in
            guard let self = self else { return }

            // REST API로 전송 (안정성 확보)
            let message = try await chatRepository.sendMessage(
                roomId: self.roomId,
                content: content
            )

            // 서버 응답으로 받은 메시지를 UI에 추가
            send(.appendMessage(message))
        },
        onError: { error in
            // 전송 실패 시 재시도 가능
            return .setError("메시지 전송 실패")
        }
    )
```

**Socket 전송 vs REST 전송**:
```
[Socket 전송의 문제]
- 연결 끊김 시 메시지 유실
- 전송 성공 여부 확인 어려움
- 재전송 로직 복잡

[REST 전송의 장점]
- HTTP 응답으로 성공 확인
- 실패 시 명확한 에러 처리
- 재시도 로직 단순
- 서버 로그로 추적 가능
```

**고려사항**:
1. **수신은 Socket, 전송은 REST**: 실시간성과 안정성 모두 확보
2. **중복 방지**: 서버에서 chatId로 중복 체크

---

### 5.4 Pending Queue (메시지 순서 보장)

**구현 방법**:
```swift
// ChatReactor.swift
struct State {
    var messages: [ChatMessageEntity] = []
    var isInitialLoadComplete: Bool = false
    var pendingSocketMessages: [ChatMessageEntity] = []  // 대기 큐
}

// 소켓 메시지 수신 시
case .socketMessageReceived(let message):
    if currentState.isInitialLoadComplete {
        // 로딩 완료 → 바로 추가
        return .just(.appendMessage(message))
    } else {
        // 로딩 중 → 큐에 저장
        return .just(.addToPendingQueue(message))
    }

// 초기 로딩 완료 시
case .initialLoadComplete:
    return Observable.concat([
        .just(.setInitialLoadComplete(true)),
        .just(.flushPendingQueue)  // 큐의 메시지 일괄 추가
    ])

// Reduce
case .flushPendingQueue:
    newState.messages.append(contentsOf: newState.pendingSocketMessages)
    newState.pendingSocketMessages = []
```

**문제 상황 및 해결**:
```
[문제 상황]
1. 채팅방 진입 → Socket 연결 + CoreData/API 로딩 동시 시작
2. Socket이 먼저 메시지 수신 (0.1초)
3. CoreData 로딩 완료 (1초) → setMessages로 덮어씀
4. Socket 메시지 사라짐!

[해결]
1. 로딩 중 수신된 Socket 메시지 → pendingQueue에 임시 저장
2. 로딩 완료 후 → pendingQueue 메시지를 messages에 추가
3. 메시지 유실 없음!
```

---

### 5.5 채팅 페이지네이션 (30개 단위 + Prefetching)

**구현 방법**:
```swift
// 초기 로딩: 최근 30개만
let recentMessages = try await chatStorage.fetchRecentMessages(
    roomId: roomId,
    limit: 30
)

// Prefetching (5개 남았을 때)
func tableView(_ tableView: UITableView,
               willDisplay cell: UITableViewCell,
               forRowAt indexPath: IndexPath) {
    // 상단 5개 이내 도달 시
    if indexPath.row < 5 && !reactor.currentState.isLoadingMore {
        reactor.action.onNext(.loadPreviousMessages)
    }
}

// 이전 메시지 로드
case .loadPreviousMessages:
    guard !currentState.isLoadingMore,
          let oldestMessage = currentState.messages.first else {
        return .empty()
    }

    return run(operation: { send in
        send(.setLoadingMore(true))

        let previousMessages = try await chatStorage.fetchMessagesBefore(
            roomId: roomId,
            beforeDate: oldestMessage.createdAt,
            limit: 30
        )

        send(.prependMessages(previousMessages))
        send(.setLoadingMore(false))
    }, onError: { _ in .setLoadingMore(false) })
```

**고려사항**:
1. **30개 단위**: 1만 개 전체 로드 시 3초 → 30개는 0.1초
2. **Prefetching**: 상단 도달 전에 미리 로드 → 끊김 없는 스크롤
3. **중복 방지 플래그**: `isLoadingMore`로 동시 요청 차단

---

### 5.6 푸시 알림 + 채팅방 이동

**구현 방법**:
```swift
// AppDelegate.swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                           didReceive response: UNNotificationResponse,
                           withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo

    if let roomId = userInfo["roomId"] as? String {
        navigateToChatRoom(roomId: roomId)
    }

    completionHandler()
}

func navigateToChatRoom(roomId: String) {
    // 현재 채팅방과 동일하면 무시
    if ChatStateManager.shared.isRoomActive(roomId) {
        return
    }

    // ChatViewController로 이동
    let chatVC = ChatViewController(roomId: roomId)

    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootVC = windowScene.windows.first?.rootViewController as? UINavigationController {
        rootVC.pushViewController(chatVC, animated: true)
    }
}

// 포그라운드 알림 처리
func userNotificationCenter(_ center: UNUserNotificationCenter,
                           willPresent notification: UNNotification,
                           withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo

    if let roomId = userInfo["roomId"] as? String,
       ChatStateManager.shared.isRoomActive(roomId) {
        // 현재 보고 있는 채팅방이면 알림 안 띄움
        completionHandler([])
    } else {
        completionHandler([.banner, .sound, .badge])
    }
}
```

**고려사항**:
1. **현재 방 확인**: `ChatStateManager`로 현재 활성 채팅방 ID 추적
2. **중복 알림 방지**: 같은 방에 있으면 알림 표시 안 함
3. **딥링크**: roomId로 특정 채팅방 직접 이동

---

### 5.7 새 메시지 토스트

**구현 방법**:
```swift
// ChatViewController.swift
var isScrolledToBottom: Bool {
    let bottomOffset = tableView.contentSize.height - tableView.bounds.height
    return tableView.contentOffset.y >= bottomOffset - 50  // 50pt 여유
}

// 새 메시지 수신 시
reactor.state.map { $0.messages }
    .distinctUntilChanged()
    .subscribe(onNext: { [weak self] messages in
        guard let self = self else { return }

        if self.isScrolledToBottom {
            // 하단이면 자동 스크롤
            self.scrollToBottom()
        } else {
            // 하단 아니면 토스트 표시
            self.showNewMessageToast()
        }
    })

func showNewMessageToast() {
    newMessageToast.isHidden = false

    // 3초 후 자동 숨김
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
        self?.newMessageToast.isHidden = true
    }
}

// 토스트 탭 → 최신 메시지로 이동
@objc func toastTapped() {
    scrollToBottom()
    newMessageToast.isHidden = true
}
```

**고려사항**:
1. **스크롤 위치 판단**: 하단 50pt 이내면 하단으로 간주
2. **자동 숨김**: 3초 후 토스트 자동 숨김 → UX
3. **탭 액션**: 토스트 탭 시 즉시 최신 메시지로 이동

---

## 6. 미디어 뷰어

### 6.1 이미지 뷰어 (핀치 줌, 더블 탭)

**구현 방법**:
```swift
class ImageViewerViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0

        // 더블 탭 제스처
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            // 확대 상태 → 원래 크기로
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            // 원래 크기 → 2배 확대
            let point = gesture.location(in: imageView)
            let zoomRect = zoomRectForScale(2.0, center: point)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }

    func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(
            width: scrollView.bounds.width / scale,
            height: scrollView.bounds.height / scale
        )
        let origin = CGPoint(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2
        )
        return CGRect(origin: origin, size: size)
    }
}

// UIScrollViewDelegate
extension ImageViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    // 확대 시 이미지 중앙 유지
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width / 2 + offsetX,
            y: scrollView.contentSize.height / 2 + offsetY
        )
    }
}
```

**고려사항**:
1. **줌 범위**: 1배 ~ 3배 (과도한 확대 방지)
2. **더블 탭 토글**: 확대 상태면 축소, 축소 상태면 확대
3. **중앙 유지**: 작은 이미지가 확대 시 구석으로 밀리지 않도록

---

### 6.2 PDF 뷰어

**구현 방법**:
```swift
import PDFKit

class PDFViewerViewController: UIViewController {
    private let pdfView = PDFView()

    override func viewDidLoad() {
        super.viewDidLoad()

        pdfView.autoScales = true  // 화면에 맞게 자동 스케일
        pdfView.displayMode = .singlePageContinuous  // 연속 스크롤
        pdfView.displayDirection = .vertical

        view.addSubview(pdfView)
        pdfView.frame = view.bounds
    }

    func loadPDF(from url: URL) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
    }
}
```

**고려사항**:
1. **PDFKit 사용**: 외부 라이브러리 없이 네이티브로 구현
2. **autoScales**: 화면 너비에 맞춰 자동 조절
3. **singlePageContinuous**: 페이지 구분 없이 연속 스크롤 (문서 읽기 편함)

---

### 6.3 동영상 인라인 재생

**구현 방법**:
```swift
// PostDetailViewController.swift
class VideoPlayerCell: UITableViewCell {
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?

    private let thumbnailImageView = UIImageView()
    private let playButton = UIButton()

    func configure(with videoURL: URL, thumbnail: UIImage?) {
        thumbnailImageView.image = thumbnail
        playButton.isHidden = false

        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
    }

    @objc func playTapped() {
        playButton.isHidden = true
        thumbnailImageView.isHidden = true

        player = AVPlayer(url: videoURL)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true

        // 인라인 임베딩
        if let playerVC = playerViewController {
            addSubview(playerVC.view)
            playerVC.view.frame = contentView.bounds
            player?.play()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        player?.pause()
        playerViewController?.view.removeFromSuperview()
        thumbnailImageView.isHidden = false
        playButton.isHidden = false
    }
}
```

**고려사항**:
1. **초기 썸네일**: 재생 전에는 썸네일만 표시 → 데이터 절약
2. **인라인 재생**: 전체화면 전환 없이 셀 내에서 재생
3. **셀 재사용**: prepareForReuse에서 플레이어 정리 → 메모리 관리

---

## 7. 장바구니 & 결제

### 7.1 장바구니 - 다른 가게 상품 처리

**구현 방법**:
```swift
// CartManager.swift
func addToCart(item: CartItem) {
    let currentItems = cartItemsRelay.value

    // 첫 상품의 가게 ID 확인
    if let firstItem = currentItems.first,
       firstItem.storeId != item.storeId {
        // 다른 가게 상품 → Alert 표시
        showDifferentStoreAlert(newItem: item)
        return
    }

    // 동일 가게 → 추가
    var items = currentItems
    items.append(item)
    cartItemsRelay.accept(items)
}

func showDifferentStoreAlert(newItem: CartItem) {
    let alert = UIAlertController(
        title: "장바구니 변경",
        message: "다른 가게의 상품이 장바구니에 있습니다.\n기존 장바구니를 비우고 새 상품을 담으시겠습니까?",
        preferredStyle: .alert
    )

    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
    alert.addAction(UIAlertAction(title: "비우고 담기", style: .destructive) { [weak self] _ in
        self?.clearCart()
        self?.addToCart(item: newItem)
    })

    // Present alert...
}
```

**고려사항**:
1. **가게별 분리**: 배달 앱처럼 한 주문에 한 가게만 가능
2. **사용자 선택권**: 강제 삭제가 아닌 확인 후 선택
3. **첫 상품 기준**: 빈 장바구니면 무조건 추가 가능

---

### 7.2 결제 플로우 (품절 체크 + 영수증 검증)

**구현 방법**:
```swift
// ShoppingCartViewController.swift
func processOrder() async throws {
    // 1. 품절/삭제 상품 확인
    let validation = try await orderRepository.validateCart(items: cartItems)

    if !validation.invalidItems.isEmpty {
        // 품절 상품이 있으면 Alert
        showInvalidItemsAlert(items: validation.invalidItems)
        return
    }

    // 2. 주문 번호 생성
    let order = try await orderRepository.createOrder(items: cartItems)

    // 3. Iamport 결제 실행
    let paymentResult = try await IamportManager.shared.requestPayment(
        orderCode: order.orderCode,
        amount: order.totalPrice,
        itemName: order.itemName
    )

    // 4. 서버 영수증 검증 (위·변조 방지)
    try await orderRepository.validatePayment(
        orderCode: order.orderCode,
        impUid: paymentResult.impUid  // Iamport 결제 고유 번호
    )

    // 5. 성공 → 장바구니 비우기, 주문 내역으로 이동
    CartManager.shared.clearCart()
    navigateToOrderHistory()
}

// 서버 영수증 검증 (OrderRepository)
func validatePayment(orderCode: String, impUid: String) async throws {
    // 서버가 Iamport API로 실제 결제 정보 조회
    // 금액, 상태 등 검증 후 주문 확정
    let response = try await NetworkManager.shared.fetch(
        dto: PaymentValidationResponseDTO.self,
        router: OrderRouter.validatePayment(orderCode: orderCode, impUid: impUid)
    )

    if !response.isValid {
        throw PaymentError.validationFailed
    }
}
```

**영수증 검증 플로우**:
```
[클라이언트]
1. Iamport SDK로 결제 → impUid 받음
2. impUid를 서버에 전송

[서버]
3. Iamport API로 impUid 조회
4. 실제 결제 금액 == 주문 금액 확인
5. 결제 상태 == "paid" 확인
6. 검증 성공 → 주문 확정

[왜 필요?]
- 클라이언트가 금액을 조작할 수 있음
- impUid만 있으면 실제 결제 여부 모름
- 서버가 직접 Iamport에 확인해야 안전
```

**고려사항**:
1. **결제 전 검증**: 품절/삭제 상품 미리 체크 → 결제 후 취소 방지
2. **서버 영수증 검증**: 클라이언트 조작 방지, 실제 결제 확인 필수
3. **에러 처리**: 각 단계별 실패 시 적절한 에러 메시지

---

### 7.3 주문내역 - 리뷰 작성 제한

**구현 방법**:
```swift
// OrderHistoryReactor.swift
func canWriteReview(order: OrderEntity) -> Bool {
    guard order.status == .pickedUp else { return false }
    guard order.review == nil else { return false }  // 이미 작성함

    // 픽업 후 3일 이내만 가능
    guard let pickedUpAt = order.pickedUpAt else { return false }
    let daysSincePickup = Calendar.current.dateComponents(
        [.day],
        from: pickedUpAt,
        to: Date()
    ).day ?? 0

    return daysSincePickup <= 3
}

// View
if reactor.canWriteReview(order: order) {
    reviewButton.isHidden = false
    reviewButton.setTitle("리뷰 작성", for: .normal)
} else if order.review != nil {
    reviewButton.isHidden = false
    reviewButton.setTitle("내 리뷰 보기", for: .normal)
} else {
    reviewButton.isHidden = true  // 기간 만료
}
```

**고려사항**:
1. **조건 3가지**: 픽업 완료 + 리뷰 미작성 + 3일 이내
2. **기간 제한 이유**: 오래된 주문의 리뷰는 신뢰도 낮음, 악용 방지
3. **상태별 버튼**: "리뷰 작성" / "내 리뷰 보기" / 숨김

---

## 8. 기타

### 8.1 웹뷰 브릿징 (출석체크)

**구현 방법**:
```swift
// WebViewController.swift
class WebViewController: UIViewController, WKScriptMessageHandler {
    private let webView: WKWebView

    init() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()

        // JavaScript → Native 메시지 핸들러 등록
        contentController.add(self, name: "attendanceHandler")
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        super.init(nibName: nil, bundle: nil)
    }

    // JavaScript에서 호출됨
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "attendanceHandler",
           let body = message.body as? [String: Any] {
            handleAttendance(data: body)
        }
    }

    func handleAttendance(data: [String: Any]) {
        if let isCompleted = data["completed"] as? Bool, isCompleted {
            // 출석체크 완료 처리
            showToast("출석체크 완료!")

            // Native에서 추가 로직 (포인트 적립 등)
            reactor.action.onNext(.attendanceCompleted)
        }
    }
}

// 웹에서 호출하는 JavaScript
// window.webkit.messageHandlers.attendanceHandler.postMessage({ completed: true })
```

**고려사항**:
1. **WKScriptMessageHandler**: 웹 → 네이티브 통신 표준 방법
2. **핸들러 이름 규약**: 웹 개발자와 협의하여 메시지 포맷 정의
3. **데이터 파싱**: Any 타입이므로 안전하게 타입 캐스팅

---

## 마무리 체크리스트

면접 전 다음 항목을 확인하세요:

### 코드 숙지
- [ ] ExReactorKit의 run() 함수 동작 원리
- [ ] TokenRefreshCoordinator Actor 패턴
- [ ] ImageLoadView 캐싱 전략
- [ ] ChatReactor pendingQueue 로직

### 화이트보드 연습
- [ ] 토큰 갱신 플로우 그리기
- [ ] ReactorKit 데이터 흐름 그리기
- [ ] 커서 기반 페이지네이션 vs Offset 비교

### STAR 기법 답변 준비
- [ ] 가장 어려웠던 버그 (Socket + Push 중복)
- [ ] 성능 최적화 경험 (이미지 다운샘플링)
- [ ] 설계 결정 이유 (REST 전송, Actor 사용)

---

**면접 응원합니다!** 이 문서를 참고하여 각 기능의 "어떻게"와 "왜"를 명확히 설명할 수 있도록 준비하세요.
