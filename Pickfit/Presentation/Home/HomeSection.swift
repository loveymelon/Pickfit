//
//  HomeSection.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import RxDataSources

enum HomeSectionModel {
    case main([StoreResponseDTO.Store])
    case category([Category])
}

extension HomeSectionModel: SectionModelType {
    typealias Item = HomeSectionItem

    var items: [HomeSectionItem] {
        switch self {
        case .main(let stores):
            return stores.map { .store($0) }
        case .category(let categories):
            return categories.map { .category($0) }
        }
    }

    init(original: HomeSectionModel, items: [HomeSectionItem]) {
        switch original {
        case .main:
            let stores = items.compactMap { item -> StoreResponseDTO.Store? in
                if case .store(let store) = item {
                    return store
                }
                return nil
            }
            self = .main(stores)
        case .category:
            let categories = items.compactMap { item -> Category? in
                if case .category(let category) = item {
                    return category
                }
                return nil
            }
            self = .category(categories)
        }
    }
}

enum HomeSectionItem {
    case store(StoreResponseDTO.Store)
    case category(Category)
}
