//
//  CreateCommentRequestDTO.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import Foundation

struct CreateCommentRequestDTO: Encodable {
    let content: String
    let parentCommentId: String?

    enum CodingKeys: String, CodingKey {
        case content
        case parentCommentId = "parent_comment_id"
    }
}
