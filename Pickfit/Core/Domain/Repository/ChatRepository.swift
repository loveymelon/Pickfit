//
//  ChatRepository.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

final class ChatRepository {

    // MARK: - REST API

    /// 채팅방 목록 조회
    func fetchChatRoomList() async throws -> [ChatRoomEntity] {
        let dto = try await NetworkManager.shared.fetch(
            dto: ChatRoomListResponseDTO.self,
            router: ChatRouter.fetchChatRoomList
        )

        return ChatRoomMapper.toEntities(dto.data)
    }

    /// 채팅 내역 조회 (CoreData 캐시 + API)
    func fetchChatHistory(roomId: String, next: String? = nil) async throws -> [ChatMessageEntity] {
        // 1. CoreData에서 캐시된 메시지 조회 (오프라인 지원 - 현재는 사용하지 않음)
        _ = ChatStorage.shared.fetchMessages(roomId: roomId)

        // 2. API로 최신 메시지 조회
        let dto = try await NetworkManager.shared.fetch(
            dto: ChatHistoryResponseDTO.self,
            router: ChatRouter.fetchChatHistory(roomId: roomId, next: next)
        )

        let currentUserId = KeychainAuthStorage.shared.readUserIdSync() ?? ""
        let apiMessages = ChatMessageMapper.toEntities(dto.data, currentUserId: currentUserId)

        // 3. API 응답을 CoreData에 저장 (백그라운드)
        Task {
            await ChatStorage.shared.saveMessages(apiMessages)
        }

        // 4. API 응답 반환 (최신 데이터 우선)
        return apiMessages
    }

    /// REST API로 메시지 전송 (파일 첨부 시 사용)
    func sendMessageViaAPI(roomId: String, content: String, files: [String] = []) async throws -> ChatMessageEntity {
        let dto = try await NetworkManager.shared.fetch(
            dto: ChatMessageDTO.self,
            router: ChatRouter.sendMessage(roomId: roomId, content: content, files: files)
        )

        let currentUserId = KeychainAuthStorage.shared.readUserIdSync() ?? ""
        return ChatMessageMapper.toEntity(dto, currentUserId: currentUserId)
    }

    // MARK: - Socket.IO

    /// Socket으로 실시간 메시지 수신 (CoreData 자동 저장)
    func connectToChat(roomId: String) -> AsyncStream<Result<ChatMessageEntity, NetworkError>> {
        let socketStream = SocketIOManager.shared.connectDTO(
            to: .chat(roomId: roomId),
            type: ChatMessageDTO.self
        )

        let currentUserId = KeychainAuthStorage.shared.readUserIdSync() ?? ""

        return AsyncStream { continuation in
            Task {
                for await result in socketStream {
                    switch result {
                    case .success(let dto):
                        let entity = ChatMessageMapper.toEntity(dto, currentUserId: currentUserId)

                        // 🔥 Socket 메시지를 CoreData에 자동 저장
                        await ChatStorage.shared.saveMessage(entity)

                        continuation.yield(.success(entity))

                    case .failure(let error):
                        continuation.yield(.failure(error))
                    }
                }
                continuation.finish()
            }
        }
    }

    /// Socket으로 메시지 전송 (텍스트 전용)
    func sendMessage(content: String, files: [String] = []) {
        let data: [String: Any] = [
            "content": content,
            "files": files
        ]
        SocketIOManager.shared.sendMessage(event: "message", data: data)
    }

    /// Socket 연결 종료
    func disconnectChat() {
        SocketIOManager.shared.stopAndRemoveSocket()
    }
}
