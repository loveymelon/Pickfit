//
//  StoreDetailResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import Foundation

struct StoreDetailResponseDTO: DTO {
    let storeId: String
    let category: String
    let name: String
    let description: String
    let hashTags: [String]
    let open: String
    let close: String
    let address: String
    let estimatedPickupTime: Int
    let parkingGuide: String
    let storeImageUrls: [String]
    let isPicchelin: Bool
    let isPick: Bool
    let pickCount: Int
    let totalReviewCount: Int
    let totalOrderCount: Int
    let totalRating: Double
    let creator: Creator
    let geolocation: Geolocation
    let menuList: [Menu]
    let createdAt: String
    let updatedAt: String

    struct Creator: DTO {
        let userId: String
        let nick: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case nick
        }
    }

    struct Geolocation: DTO {
        let longitude: Double
        let latitude: Double
    }

    struct Menu: DTO {
        let menuId: String
        let storeId: String
        let category: String
        let name: String
        let description: String
        let originInformation: String
        let price: Int
        let isSoldOut: Bool
        let tags: [String]
        let menuImageUrl: String
        let createdAt: String
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case menuId = "menu_id"
            case storeId = "store_id"
            case category
            case name
            case description
            case originInformation = "origin_information"
            case price
            case isSoldOut = "is_sold_out"
            case tags
            case menuImageUrl = "menu_image_url"
            case createdAt
            case updatedAt
        }
    }

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case category
        case name
        case description
        case hashTags
        case open
        case close
        case address
        case estimatedPickupTime = "estimated_pickup_time"
        case parkingGuide = "parking_guide"
        case storeImageUrls = "store_image_urls"
        case isPicchelin = "is_picchelin"
        case isPick = "is_pick"
        case pickCount = "pick_count"
        case totalReviewCount = "total_review_count"
        case totalOrderCount = "total_order_count"
        case totalRating = "total_rating"
        case creator
        case geolocation
        case menuList = "menu_list"
        case createdAt
        case updatedAt
    }
}
