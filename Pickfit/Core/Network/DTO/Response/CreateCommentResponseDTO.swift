//
//  CreateCommentResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import Foundation

struct CreateCommentResponseDTO: DTO {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: CreatorDTO

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
    }
}
