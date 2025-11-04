//
//  SignUpRequestDTO.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import Foundation

struct SignUpRequestDTO: DTO, Encodable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String
    let deviceToken: String?
}
