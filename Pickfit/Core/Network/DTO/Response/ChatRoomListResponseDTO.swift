//
//  ChatRoomListResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/11/25.
//

import Foundation

struct ChatRoomListResponseDTO: DTO {
    let data: [ChatRoomDTO]
}

struct ChatRoomDTO: DTO {
    let roomId: String
    let participants: [ParticipantDTO]
    let lastChat: LastChatDTO?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case participants
        case lastChat
        case createdAt
        case updatedAt
    }
}

struct ParticipantDTO: DTO {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}

struct LastChatDTO: DTO {
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

// ChatSenderDTO는 ChatMessageDTO.swift에 이미 정의되어 있음
