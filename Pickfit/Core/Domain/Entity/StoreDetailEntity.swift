//
//  StoreDetailEntity.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import Foundation

struct StoreDetailEntity {
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
    var isPicchelin: Bool
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

    struct Creator {
        let userId: String
        let nick: String
    }

    struct Geolocation {
        let longitude: Double
        let latitude: Double
    }

    struct Menu {
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
    }
}
