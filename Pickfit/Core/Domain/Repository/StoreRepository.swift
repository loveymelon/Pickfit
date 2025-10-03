//
//  StoreRepository.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import Foundation

final class StoreRepository {
    func fetchStores(
        category: String,
        longitude: Double,
        latitude: Double,
        orderBy: StoreRequestDTO.StoreOrderBy,
        next: String = ""
    ) async throws -> StoreResponseDTO {
        let fullCategory = "Jin\(category)"

        let request = StoreRequestDTO(
            category: fullCategory,
            longitude: longitude,
            latitude: latitude,
            next: next,
            orderBy: orderBy
        )

        let dto = try await NetworkManager.shared.fetch(
            dto: StoreResponseDTO.self,
            router: StoreRouter.fetchStore(request)
        )

        return dto
    }
}
