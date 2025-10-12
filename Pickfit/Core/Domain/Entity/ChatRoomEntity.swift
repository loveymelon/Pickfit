//
//  ChatRoomEntity.swift
//  Pickfit
//
//  Created by Claude on 10/11/25.
//

import Foundation

struct ChatRoomEntity {
    let roomId: String
    let participants: [ChatParticipantEntity]
    let lastChat: ChatLastChatEntity?
    let createdAt: String
    let updatedAt: String
    var isUnread: Bool = false  // 안읽음 여부 (CoreData와 비교하여 계산)
}

struct ChatParticipantEntity {
    let userId: String
    let nick: String
    let profileImage: String?
}

struct ChatLastChatEntity {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: ChatSenderEntity
    let files: [String]
}

// ChatSenderEntity는 ChatMessageEntity.swift에 이미 정의되어 있음
