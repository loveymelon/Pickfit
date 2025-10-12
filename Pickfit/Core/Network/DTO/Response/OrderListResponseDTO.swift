//
//  OrderListResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

// MARK: - Order List Response
struct OrderListResponseDTO: DTO {
    let data: [OrderHistoryDTO]
}

// MARK: - Order History
struct OrderHistoryDTO: DTO {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let review: ReviewDTO?
    let store: OrderStoreDTO
    let orderMenuList: [OrderHistoryMenuDTO]
    let currentOrderStatus: String
    let orderStatusTimeline: [OrderStatusDTO]
    let paidAt: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case review
        case store
        case orderMenuList = "order_menu_list"
        case currentOrderStatus = "current_order_status"
        case orderStatusTimeline = "order_status_timeline"
        case paidAt
        case createdAt
        case updatedAt
    }
}

// MARK: - Review
struct ReviewDTO: DTO {
    let id: String
    let rating: Int
}

// MARK: - Order Store
struct OrderStoreDTO: DTO {
    let id: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let hashTags: [String]
    let geolocation: GeolocationDTO
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case name
        case close
        case storeImageUrls = "store_image_urls"
        case hashTags
        case geolocation
        case createdAt
        case updatedAt
    }
}

// MARK: - Order History Menu
struct OrderHistoryMenuDTO: DTO {
    let menu: OrderMenuDetailDTO
    let quantity: Int
}

// MARK: - Order Menu Detail
struct OrderMenuDetailDTO: DTO {
    let id: String
    let category: String
    let name: String
    let description: String
    let originInformation: String
    let price: Int
    let tags: [String]
    let menuImageUrl: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case name
        case description
        case originInformation = "origin_information"
        case price
        case tags
        case menuImageUrl = "menu_image_url"
        case createdAt
        case updatedAt
    }
}

// MARK: - Order Status
struct OrderStatusDTO: DTO {
    let status: String
    let completed: Bool
    let changedAt: String?  // Optional: completed가 false일 때 없을 수 있음
}
