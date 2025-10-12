//
//  PaymentValidationMapper.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

enum PaymentValidationMapper {
    static func toEntity(_ dto: PaymentValidationResponseDTO) -> PaymentValidationEntity {
        return PaymentValidationEntity(
            paymentId: dto.paymentId,
            orderItem: toOrderItemEntity(dto.orderItem),
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    private static func toOrderItemEntity(_ dto: OrderItemDTO) -> OrderItemEntity {
        return OrderItemEntity(
            orderId: dto.orderId,
            orderCode: dto.orderCode,
            totalPrice: dto.totalPrice,
            store: toStoreEntity(dto.store),
            orderMenuList: dto.orderMenuList.map { toOrderMenuItemEntity($0) },
            paidAt: dto.paidAt,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    private static func toStoreEntity(_ dto: PaymentStoreDTO) -> PaymentStoreEntity {
        return PaymentStoreEntity(
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

    private static func toOrderMenuItemEntity(_ dto: OrderMenuItemDTO) -> OrderMenuItemEntity {
        return OrderMenuItemEntity(
            menu: toMenuEntity(dto.menu),
            quantity: dto.quantity
        )
    }

    private static func toMenuEntity(_ dto: PaymentMenuDTO) -> PaymentMenuEntity {
        return PaymentMenuEntity(
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
}
