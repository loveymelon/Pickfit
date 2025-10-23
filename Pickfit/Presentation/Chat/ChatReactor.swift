//
//  ChatReactor.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//
import Foundation
import ReactorKit
import RxSwift

final class ChatReactor: Reactor {

    private let chatRepository: ChatRepositoryProtocol
    private let roomId: String

    // 임시 큐: 초기 로딩 중 소켓 메시지 저장
    private var pendingSocketMessages: [ChatMessageEntity] = []
    private var isInitialLoadComplete: Bool = false

    init(roomId: String, chatRepository: ChatRepositoryProtocol = ChatRepository()) {
        self.roomId = roomId
        self.chatRepository = chatRepository
    }

    enum Action {
        case viewDidLoad
        case sendMessage(String)
        case loadMoreMessages
        case updateMessageText(String)
        case resetPrependedCount  // prependedCount 초기화용
        // 이미지 선택 관련
        case selectImages([Data])     // 이미지 피커에서 선택 (Data로 변경)
        case removeImage(Int)         // 특정 이미지 제거
        case clearImages              // 전송 후 이미지 초기화
    }

    enum Mutation {
        case setMessages([ChatMessageEntity])
        case appendMessage(ChatMessageEntity)
        case appendMessages([ChatMessageEntity])
        case prependMessages([ChatMessageEntity], count: Int)  // insertRows용 (count 필수)
        case setLoading(Bool)
        case setError(String)
        case setMessageText(String)
        case flushPendingMessages([ChatMessageEntity]) // 임시 큐 플러시
        case setPrependedCount(Int)  // insertRows 트리거용
        case setLoadingMore(Bool)  // pagination 중복 방지
        // 이미지 선택 관련
        case setSelectedImages([Data])     // 선택된 이미지 설정 (Data로 변경)
        case setIsUploadingImages(Bool)    // 이미지 업로드 중 상태
    }

    struct State {
        var messages: [ChatMessageEntity] = []
        var isLoading: Bool = false
        var isLoadingMore: Bool = false  // pagination 로딩 상태
        var prependedCount: Int = 0  // 방금 추가된 메시지 개수 (insertRows용)
        var errorMessage: String?
        var messageText: String = ""
        var isSendButtonEnabled: Bool = false
        // 이미지 선택 관련
        var selectedImageDataList: [Data] = []  // 선택된 이미지 Data (최대 5개)
        var isUploadingImages: Bool = false     // 이미지 업로드 중
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            // 소켓 연결과 초기 로딩을 병렬 실행
            return Observable.merge([
                connectToSocket(),        // 즉시 소켓 연결 (임시 큐 사용)
                loadInitialMessages()     // CoreData 또는 REST API로 초기 메시지 로드
            ])

        case .sendMessage(let content):
            return sendMessageMutation(content: content)

        case .loadMoreMessages:
            return loadPreviousMessages()

        case .updateMessageText(let text):
            return .just(.setMessageText(text))

        case .resetPrependedCount:
            return .just(.setPrependedCount(0))

        // 이미지 선택 관련
        case .selectImages(let imageDataList):
            let limitedImages = Array(imageDataList.prefix(5))  // 최대 5개 제한
            return .just(.setSelectedImages(limitedImages))

        case .removeImage(let index):
            var newImages = currentState.selectedImageDataList
            guard index >= 0 && index < newImages.count else {
                return .empty()
            }
            newImages.remove(at: index)
            return .just(.setSelectedImages(newImages))

        case .clearImages:
            return .just(.setSelectedImages([]))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setMessages(let messages):
            print("🔄 [Reduce] setMessages: \(messages.count) messages")
            // 중복 메시지 방지: 기존 메시지와 새 메시지를 병합 (chatId 기준)
            var mergedMessages = newState.messages
            for message in messages {
                if !mergedMessages.contains(where: { $0.chatId == message.chatId }) {
                    mergedMessages.append(message)
                } else {
                    print("⚠️ [Reduce] Duplicate message in setMessages ignored: \(message.chatId)")
                }
            }
            newState.messages = mergedMessages
            newState.isLoading = false

        case .appendMessage(let message):
            print("🔄 [Reduce] appendMessage: \(message.content)")
            // 중복 메시지 방지: chatId로 중복 체크
            if !newState.messages.contains(where: { $0.chatId == message.chatId }) {
                newState.messages.append(message)
            } else {
                print("⚠️ [Reduce] Duplicate message ignored: \(message.chatId)")
            }

        case .appendMessages(let messages):
            print("🔄 [Reduce] appendMessages: \(messages.count) messages")
            // 이전 메시지는 앞에 추가
            newState.messages = messages + newState.messages
            newState.isLoading = false

        case .prependMessages(let messages, let count):
            print("🔄 [Reduce] prependMessages: \(count) messages")
            // insertRows용: 배열 앞에 추가
            newState.messages = messages + newState.messages
            newState.isLoadingMore = false

        case .setLoading(let isLoading):
            print("🔄 [Reduce] setLoading: \(isLoading)")
            newState.isLoading = isLoading

        case .setLoadingMore(let isLoading):
            print("🔄 [Reduce] setLoadingMore: \(isLoading)")
            newState.isLoadingMore = isLoading

        case .setPrependedCount(let count):
            print("🔄 [Reduce] setPrependedCount: \(count)")
            newState.prependedCount = count

        case .setError(let error):
            print("🔄 [Reduce] setError: \(error)")
            newState.errorMessage = error
            newState.isLoading = false
            newState.isLoadingMore = false

        case .setMessageText(let text):
            newState.messageText = text
            // 공백 제거 후 비어있지 않으면 전송 버튼 활성화
            newState.isSendButtonEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .flushPendingMessages(let messages):
            print("🔄 [Reduce] flushPendingMessages: \(messages.count) messages")
            // 임시 큐의 메시지들을 한 번에 추가 (중복 체크)
            for message in messages {
                if !newState.messages.contains(where: { $0.chatId == message.chatId }) {
                    newState.messages.append(message)
                } else {
                    print("⚠️ [Reduce] Duplicate message in flushPending ignored: \(message.chatId)")
                }
            }

        // 이미지 선택 관련
        case .setSelectedImages(let imageDataList):
            print("🔄 [Reduce] setSelectedImages: \(imageDataList.count) images")
            newState.selectedImageDataList = imageDataList

        case .setIsUploadingImages(let isUploading):
            print("🔄 [Reduce] setIsUploadingImages: \(isUploading)")
            newState.isUploadingImages = isUploading
        }

        print("📊 [Reduce] Current state.messages.count: \(newState.messages.count)")
        return newState
    }

    // MARK: - Private Methods

    /// 초기 메시지 로드 (CoreData 우선 → REST API로 새 메시지만 가져옴)
    /// - Note: CoreData에 데이터가 있으면 마지막 메시지 이후의 새 메시지만 API로 가져옴
    ///         중복 방지 및 네트워크 효율성 향상
    private func loadInitialMessages() -> Observable<Mutation> {
        print("📥 [ChatReactor] Loading initial messages for room: \(roomId)")
        return run(
            operation: { send in
                send(.setLoading(true))

                // 1. CoreData에서 최근 30개 메시지 조회 (pagination을 위해 전체가 아닌 일부만 로드)
                let cachedMessages = ChatStorage.shared.fetchRecentMessages(roomId: self.roomId, limit: 30)

                if !cachedMessages.isEmpty {
                    // CoreData에 데이터가 있으면 먼저 표시
                    print("✅ [ChatReactor] Loaded \(cachedMessages.count) messages from CoreData")
                    send(.setMessages(cachedMessages))

                    // 2. 마지막 메시지 날짜를 기준으로 새 메시지만 API에서 가져옴
                    if let lastMessageDate = ChatStorage.shared.fetchLastMessageDate(roomId: self.roomId) {
                        print("📥 [ChatReactor] Fetching new messages after: \(lastMessageDate)")
                        let newMessages = try await self.chatRepository.fetchChatHistory(
                            roomId: self.roomId,
                            next: lastMessageDate
                        )

                        if !newMessages.isEmpty {
                            print("✅ [ChatReactor] Loaded \(newMessages.count) new messages from API")
                            // API로 받은 새 메시지를 CoreData에 저장
                            Task {
                                await ChatStorage.shared.saveMessages(newMessages)
                            }
                            send(.appendMessages(newMessages))
                        } else {
                            print("✅ [ChatReactor] No new messages from API")
                        }
                    }

                    // 초기 로딩 완료 → 임시 큐 플러시
                    self.isInitialLoadComplete = true
                    if !self.pendingSocketMessages.isEmpty {
                        print("🔄 [ChatReactor] Flushing \(self.pendingSocketMessages.count) pending socket messages")
                        send(.flushPendingMessages(self.pendingSocketMessages))
                        self.pendingSocketMessages.removeAll()
                    }
                } else {
                    // CoreData에 데이터가 없으면 REST API로 전체 메시지 조회
                    print("📥 [ChatReactor] No cached messages, fetching all from API...")
                    let messages = try await self.chatRepository.fetchChatHistory(roomId: self.roomId, next: nil)
                    print("✅ [ChatReactor] Loaded \(messages.count) messages from API")

                    // API로 받은 메시지를 CoreData에 저장
                    await ChatStorage.shared.saveMessages(messages)

                    send(.setMessages(messages))

                    // 초기 로딩 완료 → 임시 큐 플러시
                    self.isInitialLoadComplete = true
                    if !self.pendingSocketMessages.isEmpty {
                        print("🔄 [ChatReactor] Flushing \(self.pendingSocketMessages.count) pending socket messages")
                        send(.flushPendingMessages(self.pendingSocketMessages))
                        self.pendingSocketMessages.removeAll()
                    }
                }
            },
            onError: { error in
                print("❌ [ChatReactor] Failed to load messages: \(error.localizedDescription)")
                // 에러가 발생해도 초기 로딩은 완료로 처리
                self.isInitialLoadComplete = true
                return .setError(error.localizedDescription)
            }
        )
    }

    /// Socket 연결 및 실시간 메시지 수신 (임시 큐 사용)
    private func connectToSocket() -> Observable<Mutation> {
        print("🔌 [ChatReactor] Starting socket connection for room: \(roomId)")
        let stream = chatRepository.connectToChat(roomId: roomId)

        return Observable.create { observer in
            let task = Task {
                print("🔌 [ChatReactor] Socket stream started")
                for await result in stream {
                    switch result {
                    case .success(let message):
                        print("✅ [ChatReactor] Received socket message: \(message.content)")

                        // Socket으로 받은 메시지를 CoreData에 저장 (백그라운드)
                        Task {
                            await ChatStorage.shared.saveMessage(message)
                        }

                        // ✅ 알림 처리 로직
                        self.handleNotificationForMessage(message)

                        if self.isInitialLoadComplete {
                            // 초기 로딩 완료 → 즉시 UI에 반영
                            print("📨 [ChatReactor] Appending message to UI (initial load complete)")
                            observer.onNext(.appendMessage(message))
                        } else {
                            // 초기 로딩 중 → 임시 큐에 저장
                            print("📦 [ChatReactor] Queuing message (initial load in progress)")
                            self.pendingSocketMessages.append(message)
                        }

                    case .failure(let error):
                        print("❌ [ChatReactor] Socket error: \(error)")
                        observer.onNext(.setError(error.localizedDescription))
                    }
                }
                print("🔌 [ChatReactor] Socket stream ended")
            }

            return Disposables.create {
                print("🔌 [ChatReactor] Disposing socket connection")
                task.cancel()
                self.chatRepository.disconnectChat()
            }
        }
    }

    /// 메시지 전송 (REST API + 이미지 업로드)
    private func sendMessageMutation(content: String) -> Observable<Mutation> {
        print("📨 [ChatReactor] Sending message via REST API: \(content)")

        let selectedImageDataList = currentState.selectedImageDataList
        let hasImages = !selectedImageDataList.isEmpty

        if hasImages {
            print("🖼️ [ChatReactor] \(selectedImageDataList.count) images selected, will upload first")
        }

        return run(
            operation: { send in
                var filePaths: [String] = []

                // 1. 이미지가 있으면 먼저 업로드
                if hasImages {
                    send(.setIsUploadingImages(true))
                    print("📤 [ChatReactor] Starting image upload...")

                    // 1-1. 파일 메타정보 생성 (Data에서 PDF 여부 추출)
                    let fileDataList = selectedImageDataList.enumerated().map { index, data -> (data: Data, fileName: String, isPDF: Bool) in
                        // PDF 매직 넘버 확인 (%PDF)
                        var isPDF = false
                        if data.count > 4 {
                            let header = data.prefix(4)
                            if let headerString = String(data: header, encoding: .ascii), headerString == "%PDF" {
                                isPDF = true
                            }
                        }

                        let fileName = isPDF ? "file_\(Date().timeIntervalSince1970)_\(index).pdf" : ""
                        return (data, fileName, isPDF)
                    }

                    // 1-2. 파일 업로드 API 호출
                    filePaths = try await self.chatRepository.uploadFiles(
                        roomId: self.roomId,
                        fileDataList: fileDataList
                    )

                    print("✅ [ChatReactor] Files uploaded: \(filePaths)")
                    send(.setIsUploadingImages(false))
                }

                // 2. 메시지 전송 (파일 경로 포함)
                let sentMessage = try await self.chatRepository.sendMessageViaAPI(
                    roomId: self.roomId,
                    content: content,
                    files: filePaths
                )
                print("✅ [ChatReactor] Message sent successfully: \(sentMessage.chatId)")

                // 3. 전송 후 이미지 초기화
                if hasImages {
                    send(.setSelectedImages([]))
                }

                // 전송 성공 후 서버가 Socket으로 broadcast하므로
                // connectToSocket()에서 자동으로 수신됨
                // 따라서 여기서는 별도로 UI 업데이트 안 함
            },
            onError: { error in
                print("❌ [ChatReactor] Failed to send message: \(error.localizedDescription)")
                return .setError("메시지 전송 실패: \(error.localizedDescription)")
            }
        )
    }

    /// 이전 메시지 더 로드 (CoreData Pagination)
    /// - Note: CoreData에서 이전 30개를 가져와 insertRows로 추가
    ///         중복 pagination 방지를 위해 isLoadingMore 플래그 사용
    private func loadPreviousMessages() -> Observable<Mutation> {
        // 이미 로딩 중이거나 메시지가 없으면 무시
        guard !currentState.isLoadingMore,
              let oldestMessage = currentState.messages.first else {
            print("[ChatReactor] Pagination ignored: isLoadingMore or no messages")
            return .empty()
        }

        print("[ChatReactor] Loading previous messages before: \(oldestMessage.createdAt)")

        return Observable.concat([
            // 1. 로딩 시작
            .just(.setLoadingMore(true)),

            // 2. CoreData에서 이전 메시지 조회
            Observable.create { observer in
                let messages = ChatStorage.shared.fetchMessagesBefore(
                    roomId: self.roomId,
                    beforeDate: oldestMessage.createdAt,
                    limit: 30
                )

                print("[ChatReactor] Loaded \(messages.count) previous messages from CoreData")

                if messages.isEmpty {
                    // 더 이상 데이터 없음
                    observer.onNext(.setLoadingMore(false))
                    print("[ChatReactor] No more previous messages")
                } else {
                    // prependMessages + setPrependedCount
                    observer.onNext(.prependMessages(messages, count: messages.count))
                    observer.onNext(.setPrependedCount(messages.count))
                }

                observer.onCompleted()
                return Disposables.create()
            }
        ])
    }

    /// Socket으로 메시지를 받았을 때 알림 처리
    /// - 내 메시지이거나 같은 방 보는 중이면 알림 표시 안 함
    /// - 앱 실행 중(Foreground)이면 In-App Banner 표시
    /// - 배지 개수 증가
    private func handleNotificationForMessage(_ message: ChatMessageEntity) {
//        print("🔔 [ChatReactor] Handling notification for message from \(message.sender.nick)")

        // 1. 알림을 표시해야 하는지 판단
        let shouldNotify = ChatStateManager.shared.shouldShowNotification(
            for: roomId,
            isMyMessage: message.isMyMessage
        )

        if !shouldNotify {
            print("🔕 [ChatReactor] Notification blocked for message: \(message.content)")
            return
        }

        // 2. ⚠️ Socket 메시지는 배지 증가 안 함!
        // 이유: Firebase Push에서 같은 메시지에 대해 배지 증가함 (중복 방지)
        // BadgeManager.shared.incrementUnreadCount(for: roomId)
        print("📊 [ChatReactor] Socket message - badge will be incremented by push notification")

        // 3. 채팅 목록 갱신 알림 발송 (푸시 수신 시와 동일)
        DispatchQueue.main.async {
            print("📱 [ChatReactor] Posting chat push received event for list refresh")

            NotificationCenter.default.post(
                name: .chatPushReceived,
                object: nil,
                userInfo: ["roomId": message.roomId]
            )
        }
    }

    deinit {
        // Reactor 해제 시 Socket 연결 종료
        chatRepository.disconnectChat()
    }
}
