//
//  ChatMessageEntity.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

struct ChatMessageEntity {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: ChatSenderEntity
    let files: [String]
    let isMyMessage: Bool
}

struct ChatSenderEntity {
    let userId: String
    let nickname: String
    let profileImageUrl: String?
}
