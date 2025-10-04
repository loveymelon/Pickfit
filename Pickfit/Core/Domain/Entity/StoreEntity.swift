//
//  StoreEntity.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import Foundation

struct StoreEntity: Equatable {
    let storeId: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    var isPicchelin: Bool
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

    struct Geolocation: Equatable {
        let longitude: Double
        let latitude: Double
    }
}
