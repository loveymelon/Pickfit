//
//  ChatRoomDTO.swift
//  Pickfit
//
//  Created by 김진수 on 11/10/24.
//

import RealmSwift

/// Realm 채팅방 DTO
final class ChatRoomDTO: Object, @unchecked Sendable {

    @Persisted(primaryKey: true) var roomId: String
    @Persisted var lastReadChatId: String?
    @Persisted var updatedAt: String

    // ChatRoom (1) ↔ (N) Message 관계
    @Persisted var messages: List<ChatMessageDTO>

    convenience init(roomId: String) {
        self.init()
        self.roomId = roomId
        self.updatedAt = Date().iso8601String
    }
}

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
