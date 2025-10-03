//
//  StoreRequest.swift
//  Pickfit
//
//  Created by 김진수 on 10/3/25.
//

import Foundation

struct StoreRequestDTO: DTO, Encodable {
    let category: String
    let longitude: Double
    let latitude: Double
    let maxDistance: Double = 10000000
    let next: String
    let limit: Int = 5
    let orderBy: StoreOrderBy
    
    enum StoreOrderBy: String, DTO, Encodable {
        case distance
        case orders
        case reviews
    }
    
    enum CodingKeys: String, CodingKey {
        case category
        case longitude
        case latitude
        case maxDistance
        case next
        case limit
        case orderBy = "order_by"
    }
}
