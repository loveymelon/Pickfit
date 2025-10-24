//
//  ChatRepository.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

final class ChatRepository: ChatRepositoryProtocol {

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

    /// 파일 업로드 (multipart/form-data)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - fileDataList: 파일 Data와 메타정보 배열 (최대 5개)
    /// - Returns: 업로드된 파일 경로 배열
    func uploadFiles(roomId: String, fileDataList: [(data: Data, fileName: String, isPDF: Bool)]) async throws -> [String] {
        let dto = try await NetworkManager.shared.uploadMultipart(
            dto: FileUploadResponseDTO.self,
            router: ChatRouter.uploadFiles(roomId: roomId, fileDataList: fileDataList)
        )

        print("✅ [ChatRepository] File upload success: \(dto.files.count) files")
        return dto.files
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
        print("🔌 [ChatRepository] Creating socket stream for room: \(roomId)")
        let socketStream = SocketIOManager.shared.connectDTO(
            to: .chat(roomId: roomId),
            type: ChatMessageDTO.self
        )

        let currentUserId = KeychainAuthStorage.shared.readUserIdSync() ?? ""
        print("👤 [ChatRepository] Current user ID: \(currentUserId)")

        return AsyncStream { continuation in
            Task {
                print("🔄 [ChatRepository] Starting to listen to socket stream")
                for await result in socketStream {
                    switch result {
                    case .success(let dto):
                        print("✅ [ChatRepository] Received message DTO")
                        let entity = ChatMessageMapper.toEntity(dto, currentUserId: currentUserId)

                        // 🔥 Socket 메시지를 CoreData에 자동 저장
                        await ChatStorage.shared.saveMessage(entity)

                        continuation.yield(.success(entity))

                    case .failure(let error):
                        print("❌ [ChatRepository] Socket stream error: \(error)")
                        continuation.yield(.failure(error))
                    }
                }
                print("🔌 [ChatRepository] Socket stream ended")
                continuation.finish()
            }
        }
    }

    /// Socket 연결 종료
    func disconnectChat() {
        SocketIOManager.shared.stopAndRemoveSocket()
    }
}
