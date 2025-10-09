//
//  ChatRepository.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

final class ChatRepository {

    // MARK: - REST API

    /// 채팅 내역 조회
    func fetchChatHistory(roomId: String, next: String? = nil) async throws -> [ChatMessageEntity] {
        let dto = try await NetworkManager.shared.fetch(
            dto: ChatHistoryResponseDTO.self,
            router: ChatRouter.fetchChatHistory(roomId: roomId, next: next)
        )

        let currentUserId = KeychainAuthStorage.shared.readUserIdSync() ?? ""
        return ChatMessageMapper.toEntities(dto.data, currentUserId: currentUserId)
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

    /// Socket으로 실시간 메시지 수신
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
