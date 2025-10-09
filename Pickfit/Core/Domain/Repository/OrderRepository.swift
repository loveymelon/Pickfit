//
//  OrderRepository.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import Foundation

final class OrderRepository {
    func createOrder(
        storeId: String,
        orderMenuList: [OrderMenuDTO],
        totalPrice: Int
    ) async throws -> OrderEntity {
        let request = OrderRequestDTO(
            storeId: storeId,
            orderMenuList: orderMenuList,
            totalPrice: totalPrice
        )

        let dto = try await NetworkManager.shared.fetch(
            dto: OrderResponseDTO.self,
            router: OrderRouter.createOrder(request)
        )

        let entity = OrderMapper.toEntity(dto)
        return entity
    }
}
