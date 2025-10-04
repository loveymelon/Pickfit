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
    ) async throws -> (stores: [StoreEntity], nextCursor: String) {
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

        let entities = StoreMapper.dtoListToEntityList(dto.data)
        return (stores: entities, nextCursor: dto.nextCursor)
    }

    func fetchBanners() async throws -> BannerResponseDTO {
        let dto = try await NetworkManager.shared.fetch(
            dto: BannerResponseDTO.self,
            router: StoreRouter.fetchBanner
        )

        return dto
    }

    func fetchStoreDetail(storeId: String) async throws -> StoreDetailEntity {
        let dto = try await NetworkManager.shared.fetch(
            dto: StoreDetailResponseDTO.self,
            router: StoreRouter.fetchStoreDetail(storeId)
        )

        let entity = StoreDetailMapper.dtoToEntity(dto)
        return entity
    }
}
