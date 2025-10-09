//
//  OrderResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import Foundation

struct OrderResponseDTO: DTO {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case createdAt
        case updatedAt
    }
}
