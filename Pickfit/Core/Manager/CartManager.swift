//
//  CartManager.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import Foundation
import RxSwift
import RxRelay

struct CartItem {
    let menu: StoreDetailEntity.Menu
    let size: String
    let color: String
    var quantity: Int
}

final class CartManager {
    static let shared = CartManager()

    private init() {}

    // BehaviorRelay로 장바구니 상태 관리
    private let cartItemsRelay = BehaviorRelay<[CartItem]>(value: [])

    // Observable로 외부에서 구독 가능
    var cartItems: Observable<[CartItem]> {
        return cartItemsRelay.asObservable()
    }

    // 현재 장바구니 아이템들
    var currentCartItems: [CartItem] {
        return cartItemsRelay.value
    }

    // 총 수량 계산
    var totalQuantity: Int {
        return cartItemsRelay.value.reduce(0) { $0 + $1.quantity }
    }

    // 총 금액 계산
    var totalPrice: Int {
        return cartItemsRelay.value.reduce(0) { $0 + ($1.menu.price * $1.quantity) }
    }

    // 장바구니에 아이템 추가
    func addToCart(menu: StoreDetailEntity.Menu, size: String, color: String) {
        var items = cartItemsRelay.value

        // 같은 메뉴+사이즈가 이미 있는지 확인 (색상은 무시)
        if let index = items.firstIndex(where: { $0.menu.menuId == menu.menuId && $0.size == size }) {
            // 이미 있으면 수량만 증가 (색상은 최신 선택으로 업데이트)
            items[index].quantity += 1
            print("🛒 [CartManager] 수량 증가: \(menu.name) (\(size)) - 수량: \(items[index].quantity)")
        } else {
            // 없으면 새로 추가
            let newItem = CartItem(menu: menu, size: size, color: color, quantity: 1)
            items.append(newItem)
            print("🛒 [CartManager] 새로 추가: \(menu.name) (\(size), \(color))")
        }

        cartItemsRelay.accept(items)
        printCartStatus()
    }

    // 장바구니에서 아이템 제거
    func removeFromCart(at index: Int) {
        var items = cartItemsRelay.value
        guard index < items.count else { return }

        let removedItem = items.remove(at: index)
        print("🛒 [CartManager] 제거: \(removedItem.menu.name)")

        cartItemsRelay.accept(items)
        printCartStatus()
    }

    // 수량 변경
    func updateQuantity(at index: Int, quantity: Int) {
        var items = cartItemsRelay.value
        guard index < items.count else { return }

        if quantity <= 0 {
            removeFromCart(at: index)
        } else {
            items[index].quantity = quantity
            cartItemsRelay.accept(items)
            printCartStatus()
        }
    }

    // 장바구니 비우기
    func clearCart() {
        cartItemsRelay.accept([])
        print("🛒 [CartManager] 장바구니 비우기")
    }

    // 장바구니 상태 출력 (디버깅용)
    private func printCartStatus() {
        let items = cartItemsRelay.value
        print("\n🛒 === 장바구니 현황 (CartManager) ===")
        print("총 \(items.count)개 종류")
        print("총 수량: \(totalQuantity)개")
        print("총 금액: \(totalPrice)원")

        for (index, item) in items.enumerated() {
            print("  [\(index + 1)] \(item.menu.name)")
            print("      사이즈: \(item.size), 색상: \(item.color), 수량: \(item.quantity)")
            print("      가격: \(item.menu.price)원 × \(item.quantity) = \(item.menu.price * item.quantity)원")
        }
        print("=====================================\n")
    }
}
