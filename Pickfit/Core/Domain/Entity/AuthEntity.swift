//
//  AuthEntity.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation

struct AuthEntity {
    let userId: String
    let email: String
    let nickname: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
}