//
//  PaymentValidationResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

// MARK: - Payment Validation Response
struct PaymentValidationResponseDTO: DTO {
    let paymentId: String
    let orderItem: OrderItemDTO
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
        case orderItem = "order_item"
        case createdAt
        case updatedAt
    }
}

// MARK: - Order Item
struct OrderItemDTO: DTO {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let store: PaymentStoreDTO
    let orderMenuList: [OrderMenuItemDTO]
    let paidAt: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case store
        case orderMenuList = "order_menu_list"
        case paidAt
        case createdAt
        case updatedAt
    }
}

// MARK: - Payment Store
struct PaymentStoreDTO: DTO {
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

// MARK: - Geolocation
struct GeolocationDTO: DTO {
    let longitude: Double
    let latitude: Double
}

// MARK: - Order Menu Item
struct OrderMenuItemDTO: DTO {
    let menu: PaymentMenuDTO
    let quantity: Int
}

// MARK: - Payment Menu
struct PaymentMenuDTO: DTO {
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
