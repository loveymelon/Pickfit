//
//  KakaoRequestDTO.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import Foundation

struct KakaoRequestDTO: DTO, Encodable {
    let oauthToken: String
    let deviceToken: String?  // APNS deviceToken (옵셔널: 토큰이 없을 수도 있음)
}