//
//  CreateChatRoomResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import Foundation

struct CreateChatRoomResponseDTO: DTO {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [Participant]
    let lastChat: LastChat?

    struct Participant: Codable {
        let userId: String
        let nick: String
        let profileImage: String?

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case nick
            case profileImage
        }
    }

    struct LastChat: Codable {
        let chatId: String
        let roomId: String
        let content: String
        let createdAt: String
        let updatedAt: String
        let sender: Sender
        let files: [String]

        struct Sender: Codable {
            let userId: String
            let nick: String
            let profileImage: String?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case nick
                case profileImage
            }
        }

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

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case createdAt
        case updatedAt
        case participants
        case lastChat
    }
}
