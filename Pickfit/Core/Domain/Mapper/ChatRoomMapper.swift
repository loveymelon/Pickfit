//
//  ChatRoomMapper.swift
//  Pickfit
//
//  Created by 김진수 on 10/11/25.
//

import Foundation

enum ChatRoomMapper {
    static func toEntities(_ dtos: [ChatRoomDTO]) -> [ChatRoomEntity] {
        return dtos.map { toEntity($0) }
    }

    static func toEntity(_ dto: ChatRoomDTO) -> ChatRoomEntity {
        return ChatRoomEntity(
            roomId: dto.roomId,
            participants: dto.participants.map { toParticipantEntity($0) },
            lastChat: dto.lastChat.map { toLastChatEntity($0) },
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    private static func toParticipantEntity(_ dto: ParticipantDTO) -> ChatParticipantEntity {
        return ChatParticipantEntity(
            userId: dto.userId,
            nick: dto.nick,
            profileImage: dto.profileImage
        )
    }

    private static func toLastChatEntity(_ dto: LastChatDTO) -> ChatLastChatEntity {
        return ChatLastChatEntity(
            chatId: dto.chatId,
            roomId: dto.roomId,
            content: dto.content,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            sender: toSenderEntity(dto.sender),
            files: dto.files
        )
    }

    private static func toSenderEntity(_ dto: ChatSenderDTO) -> ChatSenderEntity {
        return ChatSenderEntity(
            userId: dto.userId,
            nickname: dto.nick,
            profileImageUrl: dto.profileImage
        )
    }
}
