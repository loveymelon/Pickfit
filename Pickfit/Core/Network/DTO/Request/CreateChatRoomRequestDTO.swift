//
//  CreateChatRoomRequestDTO.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import Foundation

struct CreateChatRoomRequestDTO: Codable {
    let opponentId: String

    enum CodingKeys: String, CodingKey {
        case opponentId = "opponent_id"
    }
}
