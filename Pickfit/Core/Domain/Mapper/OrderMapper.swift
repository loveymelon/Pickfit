//
//  OrderMapper.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import Foundation

struct OrderMapper {
    static func toEntity(_ dto: OrderResponseDTO) -> OrderEntity {
        return OrderEntity(
            orderId: dto.orderId,
            orderCode: dto.orderCode,
            totalPrice: dto.totalPrice,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }
}
