//
//  ShoppingCartReactor.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import RxSwift
import ReactorKit

final class ShoppingCartReactor: Reactor {
    enum Action {
        case viewDidLoad
        case deleteItem(Int)
        case updateQuantity(Int, Int) // index, quantity
    }

    enum Mutation {
        case setViewDidLoad
        case setCartItems([CartItem])
    }

    struct State {
        var isViewLoaded: Bool = false
        var cartItems: [CartItem] = []

        // Computed properties
        var totalPrice: Int {
            return cartItems.reduce(0) { total, item in
                return total + (item.menu.price * item.quantity)
            }
        }

        var totalQuantity: Int {
            return cartItems.reduce(0) { total, item in
                return total + item.quantity
            }
        }
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.just(.setViewDidLoad)

        case .deleteItem(let index):
            CartManager.shared.removeFromCart(at: index)
            return Observable.empty()

        case .updateQuantity(let index, let quantity):
            CartManager.shared.updateQuantity(at: index, quantity: quantity)
            return Observable.empty()
        }
    }

    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let cartMutation = CartManager.shared.cartItems
            .map { Mutation.setCartItems($0) }

        return Observable.merge(mutation, cartMutation)
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setViewDidLoad:
            newState.isViewLoaded = true

        case .setCartItems(let items):
            newState.cartItems = items
        }

        return newState
    }
}
