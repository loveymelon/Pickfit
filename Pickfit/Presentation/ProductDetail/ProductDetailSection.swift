//
//  ProductDetailSection.swift
//  Pickfit
//
//  Created by 김진수 on 10/7/25.
//

import RxDataSources

enum ProductDetailSection {
    case images([ProductDetailItem])
    case productInfo([ProductDetailItem])
}

enum ProductDetailItem {
    case image(String)
    case info(ProductInfo)
}

extension ProductDetailSection: SectionModelType {
    typealias Item = ProductDetailItem

    var items: [ProductDetailItem] {
        switch self {
        case .images(let items):
            return items
        case .productInfo(let items):
            return items
        }
    }

    init(original: ProductDetailSection, items: [ProductDetailItem]) {
        switch original {
        case .images:
            self = .images(items)
        case .productInfo:
            self = .productInfo(items)
        }
    }
}
