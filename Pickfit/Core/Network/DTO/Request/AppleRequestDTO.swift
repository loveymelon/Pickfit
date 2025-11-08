//
//  AppleRequestDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/12/25.
//

import Foundation

struct AppleRequestDTO: DTO, Encodable {
    let idToken: String
    let nick: String?
    let deviceToken: String?

    // nil 값을 JSON에서 제외하기 위한 custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(idToken, forKey: .idToken)

        // nick이 nil이 아닐 때만 인코딩
        if let nick = nick {
            try container.encode(nick, forKey: .nick)
        }

        // deviceToken이 nil이 아닐 때만 인코딩
        if let deviceToken = deviceToken {
            try container.encode(deviceToken, forKey: .deviceToken)
        }
    }

    enum CodingKeys: String, CodingKey {
        case idToken
        case nick
        case deviceToken
    }
}
