//
//  StoreResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import Foundation

struct StoreResponseDTO: DTO {
    let data: [Store]
    let nextCursor: String

    struct Store: DTO, Equatable {
        let storeId: String
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
        let geolocation: Geolocation
        let distance: Double
        let createdAt: String
        let updatedAt: String

        struct Geolocation: DTO, Equatable {
            let longitude: Double
            let latitude: Double
        }

        enum CodingKeys: String, CodingKey {
            case storeId = "store_id"
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
            case distance
            case createdAt
            case updatedAt
        }
    }

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}
