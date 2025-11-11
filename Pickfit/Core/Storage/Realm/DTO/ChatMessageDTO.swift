//
//  ChatMessageDTO.swift
//  Pickfit
//
//  Created by 김진수 on 11/10/24.
//

import RealmSwift

/// Realm 채팅 메시지 DTO
final class ChatMessageDTO: Object, @unchecked Sendable {

    @Persisted(primaryKey: true) var chatId: String
    @Persisted var roomId: String
    @Persisted var content: String
    @Persisted var createdAt: String
    @Persisted var updatedAt: String

    // Sender 정보
    @Persisted var senderId: String
    @Persisted var senderNick: String
    @Persisted var senderProfileImage: String?

    // Files (JSON 문자열로 저장)
    @Persisted var filesJSON: String?

    @Persisted var isMyMessage: Bool

    // ChatRoom과의 역관계 (옵셔널)
    @Persisted(originProperty: "messages") var room: LinkingObjects<ChatRoomDTO>

    convenience init(entity: ChatMessageEntity) {
        self.init()
        self.chatId = entity.chatId
        self.roomId = entity.roomId
        self.content = entity.content
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
        self.senderId = entity.sender.userId
        self.senderNick = entity.sender.nickname
        self.senderProfileImage = entity.sender.profileImageUrl
        self.isMyMessage = entity.isMyMessage

        // files 배열 → JSON 문자열
        if !entity.files.isEmpty,
           let jsonData = try? JSONEncoder().encode(entity.files),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            self.filesJSON = jsonString
        }
    }

    func toDomain() -> ChatMessageEntity {
        // filesJSON → [String] 변환
        var files: [String] = []
        if let filesJSON = filesJSON,
           let data = filesJSON.data(using: .utf8) {
            files = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }

        return ChatMessageEntity(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sender: ChatSenderEntity(
                userId: senderId,
                nickname: senderNick,
                profileImageUrl: senderProfileImage
            ),
            files: files,
            isMyMessage: isMyMessage
        )
    }
}
