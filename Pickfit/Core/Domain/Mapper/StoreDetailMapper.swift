//
//  StoreDetailMapper.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import Foundation

struct StoreDetailMapper {
    static func dtoToEntity(_ dto: StoreDetailResponseDTO) -> StoreDetailEntity {
        return StoreDetailEntity(
            storeId: dto.storeId,
            category: dto.category,
            name: dto.name,
            description: dto.description,
            hashTags: dto.hashTags,
            open: dto.open,
            close: dto.close,
            address: dto.address,
            estimatedPickupTime: dto.estimatedPickupTime,
            parkingGuide: dto.parkingGuide,
            storeImageUrls: dto.storeImageUrls,
            isPicchelin: dto.isPicchelin,
            isPick: dto.isPick,
            pickCount: dto.pickCount,
            totalReviewCount: dto.totalReviewCount,
            totalOrderCount: dto.totalOrderCount,
            totalRating: dto.totalRating,
            creator: StoreDetailEntity.Creator(
                userId: dto.creator.userId,
                nick: dto.creator.nick
            ),
            geolocation: StoreDetailEntity.Geolocation(
                longitude: dto.geolocation.longitude,
                latitude: dto.geolocation.latitude
            ),
            menuList: dto.menuList,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }
}
