//
//  RefreshTokenRequestDTO.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import Foundation

struct RefreshTokenRequestDTO: DTO, Encodable {
    let refreshToken: String
}