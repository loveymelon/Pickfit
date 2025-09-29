//
//  AuthMapper.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation

struct AuthMapper {
    static func dtoToEntity(_ dto: KakaoResponseDTO) -> AuthEntity {
        return AuthEntity(
            userId: dto.userId,
            email: dto.email,
            nickname: dto.nick,
            profileImage: dto.profileImage,
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken
        )
    }
}