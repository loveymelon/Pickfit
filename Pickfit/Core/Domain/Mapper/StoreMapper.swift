//
//  StoreMapper.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import Foundation

struct StoreMapper {
    static func dtoToEntity(_ dto: StoreResponseDTO.Store) -> StoreEntity {
        return StoreEntity(
            storeId: dto.storeId,
            category: dto.category,
            name: dto.name,
            close: dto.close,
            storeImageUrls: dto.storeImageUrls,
            isPicchelin: dto.isPicchelin,
            isPick: dto.isPick,
            pickCount: dto.pickCount,
            hashTags: dto.hashTags,
            totalRating: dto.totalRating,
            totalOrderCount: dto.totalOrderCount,
            totalReviewCount: dto.totalReviewCount,
            geolocation: StoreEntity.Geolocation(
                longitude: dto.geolocation.longitude,
                latitude: dto.geolocation.latitude
            ),
            distance: dto.distance,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    static func dtoListToEntityList(_ dtoList: [StoreResponseDTO.Store]) -> [StoreEntity] {
        return dtoList.map { dtoToEntity($0) }
    }
}
