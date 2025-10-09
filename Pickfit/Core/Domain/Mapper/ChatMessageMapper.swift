//
//  ChatMessageMapper.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

enum ChatMessageMapper {
    static func toEntity(_ dto: ChatMessageDTO, currentUserId: String) -> ChatMessageEntity {
        return ChatMessageEntity(
            chatId: dto.chatId,
            roomId: dto.roomId,
            content: dto.content,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            sender: toSenderEntity(dto.sender),
            files: dto.files,
            isMyMessage: dto.sender.userId == currentUserId
        )
    }

    static func toEntities(_ dtos: [ChatMessageDTO], currentUserId: String) -> [ChatMessageEntity] {
        return dtos.map { toEntity($0, currentUserId: currentUserId) }
    }

    private static func toSenderEntity(_ dto: ChatSenderDTO) -> ChatSenderEntity {
        return ChatSenderEntity(
            userId: dto.userId,
            nickname: dto.nick,
            profileImageUrl: dto.profileImage
        )
    }
}
