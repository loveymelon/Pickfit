//
//  ChatMessageDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

// MARK: - Chat History Response
struct ChatHistoryResponseDTO: DTO {
    let data: [ChatMessageDTO]
}

// MARK: - Single Chat Message (Socket & REST)
struct ChatMessageDTO: DTO {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: ChatSenderDTO
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case roomId = "room_id"
        case content
        case createdAt
        case updatedAt
        case sender
        case files
    }
}

// MARK: - Chat Sender
struct ChatSenderDTO: DTO {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}
