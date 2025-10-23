//
//  ChatListReactor.swift
//  Pickfit
//
//  Created by Claude on 10/11/25.
//

import Foundation
import ReactorKit
import RxSwift

final class ChatListReactor: Reactor {

    private let chatRepository: ChatRepository

    init(chatRepository: ChatRepository = ChatRepository()) {
        self.chatRepository = chatRepository
    }

    enum Action {
        case viewDidLoad
        case viewIsAppearing
        case refresh
        case receivedPushNotification
        case selectChatRoom(ChatRoomEntity)
        case changeFilter(ChatFilter)
    }

    enum Mutation {
        case setAllChatRooms([ChatRoomEntity])
        case setFilteredChatRooms([ChatRoomEntity])
        case setLoading(Bool)
        case setError(String)
        case setSelectedRoom(ChatRoomEntity?)
        case setFilter(ChatFilter)
    }

    struct State {
        var allChatRooms: [ChatRoomEntity] = []
        var filteredChatRooms: [ChatRoomEntity] = []
        var currentFilter: ChatFilter = .all
        var isLoading: Bool = false
        var errorMessage: String?
        var selectedRoom: ChatRoomEntity?
    }

    enum ChatFilter {
        case all
        case unread
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        print("⚡️ [ChatListReactor] Action received: \(action)")
        print("⚡️ [ChatListReactor] Current state before action - rooms: \(currentState.allChatRooms.count), loading: \(currentState.isLoading)")

        switch action {
        case .viewDidLoad:
            // viewDidLoad는 한 번만 실행되므로 아무것도 하지 않음
            print("⚡️ [ChatListReactor] viewDidLoad - returning empty")
            return Observable.empty()

        case .viewIsAppearing:
            print("⚡️ [ChatListReactor] viewIsAppearing - calling fetchChatRooms()")
            return fetchChatRooms()

        case .refresh:
            print("⚡️ [ChatListReactor] refresh - calling fetchChatRooms()")
            return fetchChatRooms()

        case .receivedPushNotification:
            print("⚡️ [ChatListReactor] receivedPushNotification - calling fetchChatRooms()")
            return fetchChatRooms()

        case .selectChatRoom(let room):
            return .just(.setSelectedRoom(room))

        case .changeFilter(let filter):
            return .just(.setFilter(filter))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setAllChatRooms(let rooms):
            print("📦 [ChatListReactor] Setting all chat rooms: \(rooms.count) items")
            newState.allChatRooms = rooms
            newState.isLoading = false
            // 현재 필터에 따라 필터링
            newState.filteredChatRooms = filterChatRooms(rooms, filter: state.currentFilter)

        case .setFilteredChatRooms(let rooms):
            print("🔍 [ChatListReactor] Filtered chat rooms: \(rooms.count) items")
            newState.filteredChatRooms = rooms

        case .setLoading(let isLoading):
            print("⏳ [ChatListReactor] Loading: \(isLoading)")
            newState.isLoading = isLoading

        case .setError(let error):
            print("❌ [ChatListReactor] Error: \(error)")
            newState.errorMessage = error
            newState.isLoading = false

        case .setSelectedRoom(let room):
            if let room = room {
                print("👆 [ChatListReactor] Room selected: \(room.roomId)")
            } else {
                print("👆 [ChatListReactor] Room deselected")
            }
            newState.selectedRoom = room

        case .setFilter(let filter):
            print("🔍 [ChatListReactor] Filter changed: \(filter)")
            newState.currentFilter = filter
            newState.filteredChatRooms = filterChatRooms(state.allChatRooms, filter: filter)
        }

        return newState
    }

    private func filterChatRooms(_ rooms: [ChatRoomEntity], filter: ChatFilter) -> [ChatRoomEntity] {
        switch filter {
        case .all:
            return rooms
        case .unread:
            // isUnread가 true인 방만 표시
            return rooms.filter { $0.isUnread }
        }
    }

    private func fetchChatRooms() -> Observable<Mutation> {
        print("📡 [ChatListReactor] fetchChatRooms() called - starting API fetch")

        return run(
            operation: { send in
                print("📡 [ChatListReactor] Setting loading to true")
                send(.setLoading(true))

                print("📡 [ChatListReactor] Calling chatRepository.fetchChatRoomList()")
                // 1. API로 채팅방 목록 조회
                let apiRooms = try await self.chatRepository.fetchChatRoomList()
                print("✅ [ChatListReactor] API returned \(apiRooms.count) chat rooms")

                // 2. 각 방의 안읽음 여부 판단 (CoreData lastChatId와 비교)
                let roomsWithUnread = apiRooms.map { room -> ChatRoomEntity in
                    var updatedRoom = room

                    // CoreData에서 해당 방의 마지막 저장된 메시지 ID 조회
                    if let lastSavedChatId = ChatStorage.shared.fetchLastChatId(roomId: room.roomId) {
                        // API의 lastChat.chatId와 다르면 안읽음
                        updatedRoom.isUnread = (room.lastChat?.chatId != lastSavedChatId)
                    } else {
                        // CoreData에 메시지 없음 = 한 번도 안 읽음
                        updatedRoom.isUnread = (room.lastChat != nil)
                    }

                    return updatedRoom
                }

                print("📡 [ChatListReactor] Sending setAllChatRooms with \(roomsWithUnread.count) rooms")

                // 디버깅: BadgeManager 상태 출력
                BadgeManager.shared.printStatus()

                send(.setAllChatRooms(roomsWithUnread))
            },
            onError: { error in
                print("❌ [ChatListReactor] API error: \(error)")
                print("❌ [ChatListReactor] Error details: \(error.localizedDescription)")
                return .setError(error.localizedDescription)
            }
        )
    }

    // MARK: - Mock Data (테스트용)
    private func createMockChatRooms() -> [ChatRoomEntity] {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()

        return [
            // 채팅방 1: 최근 메시지 있음
            ChatRoomEntity(
                roomId: "mock-room-1",
                participants: [
                    ChatParticipantEntity(
                        userId: "mock-user-1",
                        nick: "스타일 부티크",
                        profileImage: "https://picsum.photos/200/200?random=1"
                    ),
                    ChatParticipantEntity(
                        userId: KeychainAuthStorage.shared.readUserIdSync() ?? "me",
                        nick: "나",
                        profileImage: nil
                    )
                ],
                lastChat: ChatLastChatEntity(
                    chatId: "mock-chat-1",
                    roomId: "mock-room-1",
                    content: "네, 오후 3시에 픽업 가능합니다!",
                    createdAt: dateFormatter.string(from: now.addingTimeInterval(-300)), // 5분 전
                    updatedAt: dateFormatter.string(from: now.addingTimeInterval(-300)),
                    sender: ChatSenderEntity(
                        userId: "mock-user-1",
                        nickname: "스타일 부티크",
                        profileImageUrl: "https://picsum.photos/200/200?random=1"
                    ),
                    files: []
                ),
                createdAt: dateFormatter.string(from: now.addingTimeInterval(-86400)),
                updatedAt: dateFormatter.string(from: now.addingTimeInterval(-300))
            ),

            // 채팅방 2: 어제 메시지
            ChatRoomEntity(
                roomId: "mock-room-2",
                participants: [
                    ChatParticipantEntity(
                        userId: "mock-user-2",
                        nick: "어반 스트리트",
                        profileImage: "https://picsum.photos/200/200?random=2"
                    ),
                    ChatParticipantEntity(
                        userId: KeychainAuthStorage.shared.readUserIdSync() ?? "me",
                        nick: "나",
                        profileImage: nil
                    )
                ],
                lastChat: ChatLastChatEntity(
                    chatId: "mock-chat-2",
                    roomId: "mock-room-2",
                    content: "재고 확인해보고 연락드리겠습니다 😊",
                    createdAt: dateFormatter.string(from: now.addingTimeInterval(-86400)), // 어제
                    updatedAt: dateFormatter.string(from: now.addingTimeInterval(-86400)),
                    sender: ChatSenderEntity(
                        userId: "mock-user-2",
                        nickname: "어반 스트리트",
                        profileImageUrl: "https://picsum.photos/200/200?random=2"
                    ),
                    files: []
                ),
                createdAt: dateFormatter.string(from: now.addingTimeInterval(-86400 * 2)),
                updatedAt: dateFormatter.string(from: now.addingTimeInterval(-86400))
            ),

            // 채팅방 3: 이미지 포함 메시지
            ChatRoomEntity(
                roomId: "mock-room-3",
                participants: [
                    ChatParticipantEntity(
                        userId: "mock-user-3",
                        nick: "미니멀 룩",
                        profileImage: "https://picsum.photos/200/200?random=3"
                    ),
                    ChatParticipantEntity(
                        userId: KeychainAuthStorage.shared.readUserIdSync() ?? "me",
                        nick: "나",
                        profileImage: nil
                    )
                ],
                lastChat: ChatLastChatEntity(
                    chatId: "mock-chat-3",
                    roomId: "mock-room-3",
                    content: "실물 사진 보내드립니다",
                    createdAt: dateFormatter.string(from: now.addingTimeInterval(-86400 * 3)),
                    updatedAt: dateFormatter.string(from: now.addingTimeInterval(-86400 * 3)),
                    sender: ChatSenderEntity(
                        userId: "mock-user-3",
                        nickname: "미니멀 룩",
                        profileImageUrl: "https://picsum.photos/200/200?random=3"
                    ),
                    files: ["https://picsum.photos/400/400?random=10"]
                ),
                createdAt: dateFormatter.string(from: now.addingTimeInterval(-86400 * 5)),
                updatedAt: dateFormatter.string(from: now.addingTimeInterval(-86400 * 3))
            ),

            // 채팅방 4: 메시지 없음
            ChatRoomEntity(
                roomId: "mock-room-4",
                participants: [
                    ChatParticipantEntity(
                        userId: "mock-user-4",
                        nick: "빈티지 샵",
                        profileImage: nil
                    ),
                    ChatParticipantEntity(
                        userId: KeychainAuthStorage.shared.readUserIdSync() ?? "me",
                        nick: "나",
                        profileImage: nil
                    )
                ],
                lastChat: nil,
                createdAt: dateFormatter.string(from: now.addingTimeInterval(-86400 * 7)),
                updatedAt: dateFormatter.string(from: now.addingTimeInterval(-86400 * 7))
            )
        ]
    }
}
