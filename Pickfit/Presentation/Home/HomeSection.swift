//
//  HomeSection.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import RxDataSources

enum HomeSectionModel {
    case main([StoreEntity])
    case category([Category])
    case banner([BannerResponseDTO.Banner])
    case stores([StoreEntity])
    case product([ProductModel])
}

extension HomeSectionModel: SectionModelType {
    typealias Item = HomeSectionItem

    var items: [HomeSectionItem] {
        switch self {
        case .main(let stores):
            return stores.map { .store($0) }
        case .category(let categories):
            return categories.map { .category($0) }
        case .banner(let banners):
            return banners.map { .banner($0) }
        case .stores(let storesDetail):
            return storesDetail.map { .stores($0) }
        case .product(let products):
            return products.map { .product($0) }
        }
    }

    init(original: HomeSectionModel, items: [HomeSectionItem]) {
        switch original {
        case .main:
            let stores = items.compactMap { item -> StoreEntity? in
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
        case .banner:
            let banners = items.compactMap { item -> BannerResponseDTO.Banner? in
                if case .banner(let banner) = item {
                    return banner
                }
                return nil
            }
            self = .banner(banners)
        case .stores:
            let stores = items.compactMap { item -> StoreEntity? in
                if case .stores(let store) = item {
                    return store
                }
                return nil
            }
            self = .stores(stores)
        case .product:
            let products = items.compactMap { item -> ProductModel? in
                if case .product(let product) = item {
                    return product
                }
                return nil
            }
            self = .product(products)
        }
    }
}

enum HomeSectionItem {
    case store(StoreEntity)
    case category(Category)
    case banner(BannerResponseDTO.Banner)
    case stores(StoreEntity)
    case product(ProductModel)
}
