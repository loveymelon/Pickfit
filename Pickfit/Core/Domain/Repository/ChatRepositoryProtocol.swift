//
//  ChatRepositoryProtocol.swift
//  Pickfit
//
//  테스트 가능한 ChatRepository 프로토콜
//  - ChatRepository: 실제 네트워크/저장소 구현
//  - MockChatRepository: 테스트용 Mock 구현
//

import Foundation

protocol ChatRepositoryProtocol {

    // MARK: - REST API

    /// 채팅방 목록 조회
    func fetchChatRoomList() async throws -> [ChatRoomEntity]

    /// 채팅 내역 조회 (CoreData 캐시 + API)
    func fetchChatHistory(roomId: String, next: String?) async throws -> [ChatMessageEntity]

    /// 파일 업로드 (multipart/form-data)
    func uploadFiles(roomId: String, fileDataList: [(data: Data, fileName: String, isPDF: Bool)]) async throws -> [String]

    /// REST API로 메시지 전송 (파일 첨부 시 사용)
    func sendMessageViaAPI(roomId: String, content: String, files: [String]) async throws -> ChatMessageEntity

    // MARK: - Socket.IO

    /// Socket으로 실시간 메시지 수신
    func connectToChat(roomId: String) -> AsyncStream<Result<ChatMessageEntity, NetworkError>>

    /// Socket 연결 종료
    func disconnectChat()
}
