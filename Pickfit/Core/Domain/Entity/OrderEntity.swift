//
//  OrderEntity.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import Foundation

struct OrderEntity {
    let orderId: String
    let orderCode: String  // merchant_uid로 사용될 주문번호
    let totalPrice: Int
    let createdAt: String
    let updatedAt: String
}
