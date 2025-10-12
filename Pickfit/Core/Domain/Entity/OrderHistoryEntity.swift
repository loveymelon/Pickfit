//
//  OrderHistoryEntity.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation

struct OrderHistoryEntity {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let review: ReviewEntity?
    let store: OrderStoreEntity
    let orderMenuList: [OrderHistoryMenuEntity]
    let currentOrderStatus: OrderStatus
    let orderStatusTimeline: [OrderStatusEntity]
    let paidAt: String
    let createdAt: String
    let updatedAt: String
}

struct ReviewEntity {
    let id: String
    let rating: Int
}

struct OrderStoreEntity {
    let id: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let hashTags: [String]
    let longitude: Double
    let latitude: Double
    let createdAt: String
    let updatedAt: String
}

struct OrderHistoryMenuEntity {
    let menu: OrderMenuDetailEntity
    let quantity: Int
}

struct OrderMenuDetailEntity {
    let id: String
    let category: String
    let name: String
    let description: String
    let originInformation: String
    let price: Int
    let tags: [String]
    let menuImageUrl: String
    let createdAt: String
    let updatedAt: String
}

struct OrderStatusEntity {
    let status: OrderStatus
    let completed: Bool
    let changedAt: String?  // Optional: completed가 false일 때 빈 문자열 대신 nil
}

enum OrderStatus: String {
    case pendingApproval = "PENDING_APPROVAL"
    case approved = "APPROVED"
    case inProgress = "IN_PROGRESS"
    case readyForPickup = "READY_FOR_PICKUP"
    case pickedUp = "PICKED_UP"
    case cancelled = "CANCELLED"

    var displayText: String {
        switch self {
        case .pendingApproval: return "결제 확인 중"
        case .approved: return "주문 확인 완료"
        case .inProgress: return "상품 준비 중"
        case .readyForPickup: return "픽업 대기"
        case .pickedUp: return "픽업 완료"
        case .cancelled: return "주문 취소"
        }
    }

    var detailText: String {
        switch self {
        case .pendingApproval: return "결제 영수증을 확인하고 있어요"
        case .approved: return "가게에서 주문을 확인했어요"
        case .inProgress: return "상품을 준비하고 있어요"
        case .readyForPickup: return "픽업 준비가 완료되었어요"
        case .pickedUp: return "상품을 수령했어요"
        case .cancelled: return "주문이 취소되었어요"
        }
    }

    var progressStep: Int {
        switch self {
        case .pendingApproval: return 1
        case .approved: return 2
        case .inProgress: return 3
        case .readyForPickup: return 4
        case .pickedUp: return 5
        case .cancelled: return 0
        }
    }
}
