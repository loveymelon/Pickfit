//
//  TestFixtures.swift
//  PickfitTests
//
//  재사용 가능한 테스트 Mock 데이터
//

import Foundation
@testable import Pickfit

// MARK: - ChatMessageEntity Mock

extension ChatMessageEntity {
    /// 테스트용 Mock 메시지 생성
    static func mock(
        chatId: String = UUID().uuidString,
        roomId: String = "test_room",
        content: String = "Test message",
        createdAt: String = "2025-01-20T10:00:00.000Z",
        updatedAt: String = "2025-01-20T10:00:00.000Z",
        sender: ChatSenderEntity = .mockUser(),
        files: [String] = [],
        isMyMessage: Bool = false
    ) -> ChatMessageEntity {
        return ChatMessageEntity(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sender: sender,
            files: files,
            isMyMessage: isMyMessage
        )
    }

    /// 특정 시간 간격으로 여러 메시지 생성
    static func mockList(
        count: Int,
        roomId: String = "test_room",
        startDate: Date = Date(),
        intervalSeconds: TimeInterval = 60
    ) -> [ChatMessageEntity] {
        var messages: [ChatMessageEntity] = []
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for i in 0..<count {
            let date = startDate.addingTimeInterval(TimeInterval(i) * intervalSeconds)
            let createdAt = formatter.string(from: date)

            let message = ChatMessageEntity.mock(
                chatId: "msg_\(i)",
                roomId: roomId,
                content: "Message \(i)",
                createdAt: createdAt,
                sender: i % 2 == 0 ? .mockUser() : .mockOtherUser(),
                isMyMessage: i % 2 == 0
            )
            messages.append(message)
        }

        return messages
    }
}

// MARK: - Sender Mock

extension ChatSenderEntity {
    static func mockUser(
        userId: String = "user_1",
        nickname: String = "Test User",
        profileImageUrl: String? = nil
    ) -> ChatSenderEntity {
        return ChatSenderEntity(
            userId: userId,
            nickname: nickname,
            profileImageUrl: profileImageUrl
        )
    }

    static func mockOtherUser(
        userId: String = "user_2",
        nickname: String = "Other User",
        profileImageUrl: String? = nil
    ) -> ChatSenderEntity {
        return ChatSenderEntity(
            userId: userId,
            nickname: nickname,
            profileImageUrl: profileImageUrl
        )
    }
}

// MARK: - Date Extension for Testing

extension Date {
    /// ISO8601 문자열로 변환 (ChatMessageEntity.createdAt 형식)
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
