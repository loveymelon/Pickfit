//
//  OrderHistorySection.swift
//  Pickfit
//
//  Created by Claude on 2025-10-19.
//

import Foundation
import RxDataSources

enum OrderHistorySection {
    case banner
    case ongoing(title: String)
    case history(title: String)
}

enum OrderHistorySectionItem {
    case banner(String)
    case ongoingOrder(OrderHistoryEntity)
    case historyOrder(OrderHistoryEntity)
}

extension OrderHistorySection: SectionModelType {
    typealias Item = OrderHistorySectionItem

    var items: [OrderHistorySectionItem] {
        switch self {
        case .banner:
            return [.banner("픽핏과 함께 하는\n주문픽업을 더 편하게!")]
        case .ongoing, .history:
            return []
        }
    }

    init(original: OrderHistorySection, items: [OrderHistorySectionItem]) {
        switch original {
        case .banner:
            self = .banner
        case .ongoing(let title):
            self = .ongoing(title: title)
        case .history(let title):
            self = .history(title: title)
        }
    }
}

struct OrderHistorySectionModel {
    var model: OrderHistorySection
    var items: [OrderHistorySectionItem]
}

extension OrderHistorySectionModel: SectionModelType {
    init(original: OrderHistorySectionModel, items: [OrderHistorySectionItem]) {
        self = .init(model: original.model, items: items)
    }
}
