//
//  StoreDetailReactor.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import RxSwift
import ReactorKit

final class StoreDetailReactor: Reactor {
    private let storeId: String
    private let storeRepository: StoreRepository

    init(storeId: String, storeRepository: StoreRepository = StoreRepository()) {
        self.storeId = storeId
        self.storeRepository = storeRepository
    }

    enum Action {
        case viewDidLoad
        case viewIsAppearing
        case addToCart(menu: StoreDetailEntity.Menu, size: String, color: String)
    }

    enum Mutation {
        case setViewDidLoad
        case setLoading(Bool)
        case setStoreDetail(StoreDetailEntity)
        case setError(Error)
        case logout
        case updateCartItems([CartItem])
    }

    struct State {
        var isViewLoaded: Bool = false
        var isLoading: Bool = false
        var storeDetail: StoreDetailEntity?
        var errorMessage: String?
        var shouldNavigateToLogin: Bool = false
        var cartItems: [CartItem] = []
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.just(.setViewDidLoad)

        case .viewIsAppearing:
            return run(
                operation: { send in
                    print("📡 [API] StoreDetailReactor - Fetching store detail for ID: \(self.storeId)")
                    send(.setLoading(true))

                    let detail = try await self.storeRepository.fetchStoreDetail(storeId: self.storeId)

                    print("✅ [API] StoreDetail - Data received: \(detail.name)")
                    send(.setStoreDetail(detail))
                },
                onError: { error in
                    print("❌ [API] StoreDetailReactor error: \(error.localizedDescription)")
                    return .setError(error)
                }
            )

        case .addToCart(let menu, let size, let color):
            print("🛒 장바구니에 추가: \(menu.name), 사이즈: \(size), 색상: \(color)")
            CartManager.shared.addToCart(menu: menu, size: size, color: color)
            return Observable.empty()
        }
    }

    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let cartMutation = CartManager.shared.cartItems
            .map { Mutation.updateCartItems($0) }

        let mergedMutation = Observable.merge(
            mutation,
            cartMutation
        )

        return handleAuthError(mutation: mergedMutation, logoutMutation: .logout)
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setViewDidLoad:
            newState.isViewLoaded = true

        case .setLoading(let isLoading):
            newState.isLoading = isLoading
            newState.errorMessage = nil

        case .setStoreDetail(let detail):
            newState.isLoading = false
            newState.storeDetail = detail
            newState.errorMessage = nil

        case .setError(let error):
            newState.isLoading = false
            newState.errorMessage = error.localizedDescription

        case .logout:
            newState.shouldNavigateToLogin = true

        case .updateCartItems(let items):
            newState.cartItems = items
        }

        return newState
    }
}
