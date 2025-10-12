//
//  OrderHistoryReactor.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation
import ReactorKit
import RxSwift

final class OrderHistoryReactor: Reactor {

    private let orderRepository: OrderRepository

    init(orderRepository: OrderRepository = OrderRepository()) {
        self.orderRepository = orderRepository
    }

    enum Action {
        case viewDidLoad
        case refresh
        case selectOrder(OrderHistoryEntity)
    }

    enum Mutation {
        case setOrders([OrderHistoryEntity])
        case setLoading(Bool)
        case setError(String)
        case setSelectedOrder(OrderHistoryEntity?)
    }

    struct State {
        var orders: [OrderHistoryEntity] = []
        var isLoading: Bool = false
        var errorMessage: String?
        var selectedOrder: OrderHistoryEntity?
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        print("⚡️ [OrderHistoryReactor] Action received: \(action)")
        switch action {
        case .viewDidLoad, .refresh:
            return fetchOrders()

        case .selectOrder(let order):
            return .just(.setSelectedOrder(order))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setOrders(let orders):
            print("📦 [OrderHistoryReactor] Setting orders: \(orders.count) items")
            newState.orders = orders
            newState.isLoading = false

        case .setLoading(let isLoading):
            print("⏳ [OrderHistoryReactor] Loading: \(isLoading)")
            newState.isLoading = isLoading

        case .setError(let error):
            print("❌ [OrderHistoryReactor] Error: \(error)")
            newState.errorMessage = error
            newState.isLoading = false

        case .setSelectedOrder(let order):
            if let order = order {
                print("👆 [OrderHistoryReactor] Order selected: \(order.orderCode)")
            } else {
                print("👆 [OrderHistoryReactor] Order deselected")
            }
            newState.selectedOrder = order
        }

        return newState
    }

    private func fetchOrders() -> Observable<Mutation> {
        print("📡 [OrderHistoryReactor] Fetching from API")

        return run(
            operation: { send in
                send(.setLoading(true))
                let orders = try await self.orderRepository.fetchOrderList()
                send(.setOrders(orders))
            },
            onError: { error in
                .setError(error.localizedDescription)
            }
        )
    }
}
