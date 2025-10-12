//
//  PaymentValidationEntity.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

struct PaymentValidationEntity {
    let paymentId: String
    let orderItem: OrderItemEntity
    let createdAt: String
    let updatedAt: String
}

struct OrderItemEntity {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let store: PaymentStoreEntity
    let orderMenuList: [OrderMenuItemEntity]
    let paidAt: String
    let createdAt: String
    let updatedAt: String
}

struct PaymentStoreEntity {
    let id: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let hashTags: [String]
    let longitude: Double
    let latitude: Double
    let createdAt: String
    let updatedAt: String
}

struct OrderMenuItemEntity {
    let menu: PaymentMenuEntity
    let quantity: Int
}

struct PaymentMenuEntity {
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
}
