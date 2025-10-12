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

    func validatePayment(impUid: String) async throws -> PaymentValidationEntity {
        let dto = try await NetworkManager.shared.fetch(
            dto: PaymentValidationResponseDTO.self,
            router: OrderRouter.validatePayment(impUid: impUid)
        )

        return PaymentValidationMapper.toEntity(dto)
    }

    func fetchOrderList() async throws -> [OrderHistoryEntity] {
        print("📡 [OrderRepository] 주문 목록 API 호출 시작")

        do {
            let dto = try await NetworkManager.shared.fetch(
                dto: OrderListResponseDTO.self,
                router: OrderRouter.fetchOrderList
            )

            print("✅ [OrderRepository] 주문 목록 API 성공 - \(dto.data.count)개")
            return OrderHistoryMapper.toEntities(dto.data)

        } catch {
            print("❌ [OrderRepository] 주문 목록 API 실패: \(error)")
            throw error
        }
    }
}
