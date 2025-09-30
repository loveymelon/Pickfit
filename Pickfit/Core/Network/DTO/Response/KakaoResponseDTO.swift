//
//  KakaoResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import Foundation

struct KakaoResponseDTO: DTO {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
        case profileImage
        case accessToken
        case refreshToken
    }
}