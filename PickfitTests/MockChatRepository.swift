//
//  MockChatRepository.swift
//  PickfitTests
//
//  테스트용 Mock ChatRepository
//

import Foundation
@testable import Pickfit

final class MockChatRepository: ChatRepositoryProtocol {

    // MARK: - Mock Data Storage

    /// 테스트에서 반환할 메시지 목록
    var mockMessages: [ChatMessageEntity] = []

    /// Socket으로 전송할 메시지 큐
    var socketMessagesToSend: [ChatMessageEntity] = []

    /// fetchChatHistory 호출 횟수 추적
    var fetchChatHistoryCallCount: Int = 0

    /// sendMessageViaAPI 호출 시 반환할 메시지
    var sendMessageResponse: ChatMessageEntity?

    /// fetchChatHistory 호출 시 발생시킬 에러 (nil이면 정상 동작)
    var fetchChatHistoryError: Error?

    // MARK: - Mock Methods

    /// 채팅 내역 조회 (Mock)
    func fetchChatHistory(roomId: String, next: String? = nil) async throws -> [ChatMessageEntity] {
        fetchChatHistoryCallCount += 1

        // 에러 시뮬레이션
        if let error = fetchChatHistoryError {
            throw error
        }

        // next 파라미터 기반 필터링 (pagination 시뮬레이션)
        if let next = next {
            // next 이후 메시지만 반환
            let filtered = mockMessages.filter { $0.createdAt > next }
            return filtered
        }

        return mockMessages
    }

    /// 메시지 전송 (Mock)
    func sendMessageViaAPI(roomId: String, content: String, files: [String] = []) async throws -> ChatMessageEntity {
        // sendMessageResponse가 설정되어 있으면 반환
        if let response = sendMessageResponse {
            return response
        }

        // 기본 응답 생성
        let now = Date().toISO8601String()
        return ChatMessageEntity.mock(
            chatId: UUID().uuidString,
            roomId: roomId,
            content: content,
            createdAt: now,
            updatedAt: now,
            sender: .mockUser(),
            files: files,
            isMyMessage: true
        )
    }

    /// Socket 연결 (Mock AsyncStream)
    func connectToChat(roomId: String) -> AsyncStream<Result<ChatMessageEntity, NetworkError>> {
        return AsyncStream { continuation in
            // socketMessagesToSend의 메시지들을 순차적으로 전송
            Task {
                for message in self.socketMessagesToSend {
                    // 약간의 딜레이 (실제 네트워크 시뮬레이션)
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                    continuation.yield(.success(message))
                }

                // Stream 종료는 하지 않음 (계속 연결 유지)
            }
        }
    }

    /// Socket 연결 해제 (Mock)
    func disconnectChat() {
        // Mock에서는 별도 동작 없음
        print("📴 [MockRepository] disconnectChat called")
    }

    /// 파일 업로드 (Mock)
    func uploadFiles(roomId: String, fileDataList: [(data: Data, fileName: String, isPDF: Bool)]) async throws -> [String] {
        // Mock 파일 경로 반환
        return fileDataList.enumerated().map { index, _ in
            "/uploads/mock_file_\(index).jpg"
        }
    }

    // MARK: - Test Helper Methods

    /// Mock 데이터 리셋
    func reset() {
        mockMessages = []
        socketMessagesToSend = []
        fetchChatHistoryCallCount = 0
        sendMessageResponse = nil
        fetchChatHistoryError = nil
    }

    /// 채팅방 목록 조회 (Mock)
    func fetchChatRoomList() async throws -> [ChatRoomEntity] {
        // 테스트에서 필요 시 구현
        return []
    }

    // MARK: - Test Helper Methods

    /// 테스트용 메시지 추가
    func addMockMessage(_ message: ChatMessageEntity) {
        mockMessages.append(message)
    }

    /// Socket으로 전송할 메시지 추가
    func addSocketMessage(_ message: ChatMessageEntity) {
        socketMessagesToSend.append(message)
    }
}
