//
//  OrderHistoryMapper.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

enum OrderHistoryMapper {
    static func toEntities(_ dtos: [OrderHistoryDTO]) -> [OrderHistoryEntity] {
        return dtos.map { toEntity($0) }
    }

    static func toEntity(_ dto: OrderHistoryDTO) -> OrderHistoryEntity {
        return OrderHistoryEntity(
            orderId: dto.orderId,
            orderCode: dto.orderCode,
            totalPrice: dto.totalPrice,
            review: dto.review.map { toReviewEntity($0) },
            store: toStoreEntity(dto.store),
            orderMenuList: dto.orderMenuList.map { toMenuEntity($0) },
            currentOrderStatus: OrderStatus(rawValue: dto.currentOrderStatus) ?? .pendingApproval,
            orderStatusTimeline: dto.orderStatusTimeline.map { toStatusEntity($0) },
            paidAt: dto.paidAt,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    private static func toReviewEntity(_ dto: ReviewDTO) -> ReviewEntity {
        return ReviewEntity(
            id: dto.id,
            rating: dto.rating
        )
    }

    private static func toStoreEntity(_ dto: OrderStoreDTO) -> OrderStoreEntity {
        return OrderStoreEntity(
            id: dto.id,
            category: dto.category,
            name: dto.name,
            close: dto.close,
            storeImageUrls: dto.storeImageUrls,
            hashTags: dto.hashTags,
            longitude: dto.geolocation.longitude,
            latitude: dto.geolocation.latitude,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    private static func toMenuEntity(_ dto: OrderHistoryMenuDTO) -> OrderHistoryMenuEntity {
        return OrderHistoryMenuEntity(
            menu: toMenuDetailEntity(dto.menu),
            quantity: dto.quantity
        )
    }

    private static func toMenuDetailEntity(_ dto: OrderMenuDetailDTO) -> OrderMenuDetailEntity {
        return OrderMenuDetailEntity(
            id: dto.id,
            category: dto.category,
            name: dto.name,
            description: dto.description,
            originInformation: dto.originInformation,
            price: dto.price,
            tags: dto.tags,
            menuImageUrl: dto.menuImageUrl,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    private static func toStatusEntity(_ dto: OrderStatusDTO) -> OrderStatusEntity {
        return OrderStatusEntity(
            status: OrderStatus(rawValue: dto.status) ?? .pendingApproval,
            completed: dto.completed,
            changedAt: dto.changedAt
        )
    }
}
