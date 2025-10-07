//
//  ProductDetailReactor.swift
//  Pickfit
//
//  Created by 김진수 on 10/6/25.
//

import RxSwift
import ReactorKit
import UIKit

// MARK: - ProductInfo
struct ProductInfo {
    let name: String
    let description: String
    let material: String?
    let sizes: [String]
    let soldOutSizes: Set<String> // 품절된 사이즈들
    let manufacturingCountry: String?
    let manufacturer: String?
    let colors: [String]

    static func parse(from menu: StoreDetailEntity.Menu, allMenus: [StoreDetailEntity.Menu]) -> ProductInfo {
        // 첫 번째 메뉴(menu)에서만 제품 정보 파싱
        var material: String?
        var manufacturingCountry: String?
        var manufacturer: String?
        var colors: [String] = []

        // 색상 추출 (쉼표 split 전에)
        if let colorRange = menu.originInformation.range(of: "색상:") {
            let colorStart = colorRange.upperBound
            let remaining = menu.originInformation[colorStart...]

            var colorEnd = remaining.endIndex
            if let nextKeyRange = remaining.range(of: ", 제조사:") {
                colorEnd = nextKeyRange.lowerBound
            }

            let colorString = String(remaining[..<colorEnd]).trimmingCharacters(in: .whitespaces)
            colors = colorString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        // 나머지 정보 파싱
        let components = menu.originInformation.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for component in components {
            if component.hasPrefix("소재:") {
                material = component.replacingOccurrences(of: "소재:", with: "").trimmingCharacters(in: .whitespaces)
            } else if component.hasPrefix("제조국:") {
                manufacturingCountry = component.replacingOccurrences(of: "제조국:", with: "").trimmingCharacters(in: .whitespaces)
            } else if component.hasPrefix("제조사:") {
                manufacturer = component.replacingOccurrences(of: "제조사:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }

        // 사이즈와 품절 정보는 allMenus의 tags에서 추출
        var sizeSet: Set<String> = []
        var soldOutSizes: Set<String> = []

        for m in allMenus {
            let menuSizes = m.tags.filter { ["S", "M", "L", "XL"].contains($0.uppercased()) }
            sizeSet.formUnion(menuSizes)

            if m.isSoldOut {
                soldOutSizes.formUnion(menuSizes)
            }
        }

        // S, M, L, XL 순서로 정렬
        let sizeOrder = ["S", "M", "L", "XL"]
        let sizes = sizeOrder.filter { sizeSet.contains($0) }

        return ProductInfo(
            name: menu.name,
            description: menu.description,
            material: material,
            sizes: sizes,
            soldOutSizes: soldOutSizes,
            manufacturingCountry: manufacturingCountry,
            manufacturer: manufacturer,
            colors: colors
        )
    }
}

final class ProductDetailReactor: Reactor {
    enum Action {
        case viewDidLoad
        case selectSize(String)
        case selectColor(String)
        case addToCart
    }

    enum Mutation {
        case setViewDidLoad
        case setSelectedSize(String)
        case setSelectedColor(String)
        case setAddToCart
    }

    struct State {
        var isViewLoaded: Bool = false
        var menus: [StoreDetailEntity.Menu] = []
        var imageUrls: [String] = []
        var productInfo: ProductInfo?
        var selectedSize: String?
        var selectedColor: String?
        var shouldDismiss: Bool = false
    }

    var initialState: State

    init(menus: [StoreDetailEntity.Menu]) {
        let imageUrls = menus.map { $0.menuImageUrl }
        let productInfo = menus.first.map { ProductInfo.parse(from: $0, allMenus: menus) }
        self.initialState = State(menus: menus, imageUrls: imageUrls, productInfo: productInfo)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.just(.setViewDidLoad)
        case .selectSize(let size):
            return Observable.just(.setSelectedSize(size))
        case .selectColor(let color):
            return Observable.just(.setSelectedColor(color))
        case .addToCart:
            return Observable.just(.setAddToCart)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setViewDidLoad:
            newState.isViewLoaded = true
        case .setSelectedSize(let size):
            newState.selectedSize = size
        case .setSelectedColor(let color):
            newState.selectedColor = color
        case .setAddToCart:
            newState.shouldDismiss = true
        }

        return newState
    }

    // 선택된 메뉴 반환
    func getSelectedMenu() -> StoreDetailEntity.Menu? {
        guard let selectedSize = currentState.selectedSize else { return nil }
        return currentState.menus.first(where: { $0.tags.contains(selectedSize) })
    }
}
