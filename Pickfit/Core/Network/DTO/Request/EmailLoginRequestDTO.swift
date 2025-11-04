//
//  EmailLoginRequestDTO.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import Foundation

struct EmailLoginRequestDTO: DTO, Encodable {
    let email: String
    let password: String
    let deviceToken: String?
}
