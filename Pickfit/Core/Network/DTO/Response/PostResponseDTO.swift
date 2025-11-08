//
//  PostResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 2025-10-20.
//

import Foundation

struct PostListResponseDTO: DTO {
    let data: [PostDTO]
    let nextCursor: String

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct PostDTO: DTO {
    let postId: String
    let category: String
    let title: String
    let content: String
    let store: PostStoreDTO?
    let geolocation: GeolocationDTO
    let creator: CreatorDTO
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category
        case title
        case content
        case store
        case geolocation
        case creator
        case files
        case isLike = "is_like"
        case likeCount = "like_count"
        case createdAt
        case updatedAt
    }
}

struct PostStoreDTO: DTO {
    let id: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let isPicchelin: Bool
    let isPick: Bool
    let pickCount: Int
    let hashTags: [String]
    let totalRating: Double
    let totalOrderCount: Int
    let totalReviewCount: Int
    let geolocation: GeolocationDTO
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case name
        case close
        case storeImageUrls = "store_image_urls"
        case isPicchelin = "is_picchelin"
        case isPick = "is_pick"
        case pickCount = "pick_count"
        case hashTags
        case totalRating = "total_rating"
        case totalOrderCount = "total_order_count"
        case totalReviewCount = "total_review_count"
        case geolocation
        case createdAt
        case updatedAt
    }
}

struct CreatorDTO: DTO {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}

struct PostDetailResponseDTO: DTO {
    let postId: String
    let category: String
    let title: String
    let content: String
    let store: PostStoreDTO?
    let geolocation: GeolocationDTO
    let creator: CreatorDTO
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let comments: [CommentDTO]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category
        case title
        case content
        case store
        case geolocation
        case creator
        case files
        case isLike = "is_like"
        case likeCount = "like_count"
        case comments
        case createdAt
        case updatedAt
    }
}

struct CommentDTO: DTO {
    let commentId: String
    let content: String
    let creator: CreatorDTO
    let createdAt: String
    let replies: [ReplyDTO]?  // 대댓글

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case creator
        case createdAt
        case replies
    }
}

struct ReplyDTO: DTO {
    let commentId: String
    let content: String
    let creator: CreatorDTO
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case creator
        case createdAt
    }
}
