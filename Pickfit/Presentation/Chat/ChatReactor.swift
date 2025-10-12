//
//  ChatReactor.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import ReactorKit
import RxSwift

final class ChatReactor: Reactor {

    private let chatRepository: ChatRepository
    private let roomId: String

    init(roomId: String, chatRepository: ChatRepository = ChatRepository()) {
        self.roomId = roomId
        self.chatRepository = chatRepository
    }

    enum Action {
        case viewDidLoad
        case sendMessage(String)
        case loadMoreMessages
        case updateMessageText(String)
    }

    enum Mutation {
        case setMessages([ChatMessageEntity])
        case appendMessage(ChatMessageEntity)
        case appendMessages([ChatMessageEntity])
        case setLoading(Bool)
        case setError(String)
        case setMessageText(String)
    }

    struct State {
        var messages: [ChatMessageEntity] = []
        var isLoading: Bool = false
        var errorMessage: String?
        var messageText: String = ""
        var isSendButtonEnabled: Bool = false
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.concat([
                loadInitialMessages(),
                connectToSocket()
            ])

        case .sendMessage(let content):
            return sendMessageMutation(content: content)

        case .loadMoreMessages:
            return loadPreviousMessages()

        case .updateMessageText(let text):
            return .just(.setMessageText(text))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setMessages(let messages):
            newState.messages = messages
            newState.isLoading = false

        case .appendMessage(let message):
            newState.messages.append(message)

        case .appendMessages(let messages):
            // 이전 메시지는 앞에 추가
            newState.messages = messages + newState.messages
            newState.isLoading = false

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.errorMessage = error
            newState.isLoading = false

        case .setMessageText(let text):
            newState.messageText = text
            // 공백 제거 후 비어있지 않으면 전송 버튼 활성화
            newState.isSendButtonEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return newState
    }

    // MARK: - Private Methods

    /// 초기 메시지 로드 (REST API)
    private func loadInitialMessages() -> Observable<Mutation> {
        return run(
            operation: { send in
                send(.setLoading(true))
                let messages = try await self.chatRepository.fetchChatHistory(roomId: self.roomId)
                send(.setMessages(messages))
            },
            onError: { error in
                .setError(error.localizedDescription)
            }
        )
    }

    /// Socket 연결 및 실시간 메시지 수신
    private func connectToSocket() -> Observable<Mutation> {
        let stream = chatRepository.connectToChat(roomId: roomId)

        return Observable.create { observer in
            let task = Task {
                for await result in stream {
                    switch result {
                    case .success(let message):
                        observer.onNext(.appendMessage(message))

                    case .failure(let error):
                        observer.onNext(.setError(error.localizedDescription))
                    }
                }
            }

            return Disposables.create {
                task.cancel()
                self.chatRepository.disconnectChat()
            }
        }
    }

    /// 메시지 전송
    private func sendMessageMutation(content: String) -> Observable<Mutation> {
        // Socket으로 즉시 전송 (void 반환)
        chatRepository.sendMessage(content: content)

        // Socket에서 echo로 받은 메시지를 connectToSocket()에서 처리하므로
        // 여기서는 별도 mutation 반환 안 함
        return .empty()
    }

    /// 이전 메시지 더 로드 (페이지네이션)
    private func loadPreviousMessages() -> Observable<Mutation> {
        guard let oldestMessage = currentState.messages.first else {
            return .empty()
        }

        return run(
            operation: { send in
                send(.setLoading(true))
                let messages = try await self.chatRepository.fetchChatHistory(
                    roomId: self.roomId,
                    next: oldestMessage.createdAt
                )
                send(.appendMessages(messages))
            },
            onError: { error in
                .setError(error.localizedDescription)
            }
        )
    }

    deinit {
        // Reactor 해제 시 Socket 연결 종료
        chatRepository.disconnectChat()
    }
}
