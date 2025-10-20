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
        case setSections([OrderHistorySectionModel])
        case setLoading(Bool)
        case setError(String)
        case setSelectedOrder(OrderHistoryEntity?)
    }

    struct State {
        var orders: [OrderHistoryEntity] = []
        var sections: [OrderHistorySectionModel] = []
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
            newState.sections = buildSections(from: orders)
            newState.isLoading = false

        case .setSections(let sections):
            newState.sections = sections

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

    private func buildSections(from orders: [OrderHistoryEntity]) -> [OrderHistorySectionModel] {
        var sections: [OrderHistorySectionModel] = []

        // 1. Banner Section
        sections.append(OrderHistorySectionModel(
            model: .banner,
            items: [.banner("픽핏과 함께 하는\n주문픽업을 더 편하게!")]
        ))

        // 2. Separate ongoing and history orders
        let ongoingOrders = orders.filter { $0.currentOrderStatus != .pickedUp }
        let historyOrders = orders.filter { $0.currentOrderStatus == .pickedUp }

        // 3. Ongoing Section
        if !ongoingOrders.isEmpty {
            let ongoingItems = ongoingOrders.map { OrderHistorySectionItem.ongoingOrder($0) }
            sections.append(OrderHistorySectionModel(
                model: .ongoing(title: "주문현황"),
                items: ongoingItems
            ))
        }

        // 4. History Section
        if !historyOrders.isEmpty {
            let historyItems = historyOrders.map { OrderHistorySectionItem.historyOrder($0) }
            sections.append(OrderHistorySectionModel(
                model: .history(title: "이전 주문 내역"),
                items: historyItems
            ))
        }

        return sections
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
