//
//  StoreListReactor.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import ReactorKit
import RxSwift

final class StoreListReactor: Reactor {
    private let storeRepository: StoreRepository
    private let category: Category

    init(category: Category, storeRepository: StoreRepository = StoreRepository()) {
        self.category = category
        self.storeRepository = storeRepository
    }

    enum Action {
        case viewDidLoad
        case viewIsAppearing
        case toggleLike(index: Int)
    }

    enum Mutation {
        case setViewDidLoad
        case setLoading(Bool)
        case setStores(StoreResponseDTO)
        case setError(Error)
        case logout
        case toggleLikeState(index: Int)
    }

    struct State {
        var isViewLoaded: Bool = false
        var isLoading: Bool = false
        var stores: [StoreResponseDTO.Store] = []
        var nextCursor: String = ""
        var errorMessage: String? = nil
        var shouldNavigateToLogin: Bool = false
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.just(.setViewDidLoad)

        case .viewIsAppearing:
            return run(
                operation: { send in
                    print("📡 [API] StoreListReactor - Fetching stores for category: \(self.category.displayName)")
                    send(.setLoading(true))

                    let response = try await self.storeRepository.fetchStores(
                        category: self.category.rawValue.capitalized,
                        longitude: 127.0,
                        latitude: 37.5,
                        orderBy: .distance
                    )

                    print("✅ [API] StoreList - Stores received: \(response.data.count) items")
                    send(.setStores(response))
                },
                onError: { error in
                    print("❌ [API] StoreListReactor error: \(error.localizedDescription)")
                    return .setError(error)
                }
            )

        case .toggleLike(let index):
            return Observable.just(.toggleLikeState(index: index))
        }
    }

    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        return handleAuthError(mutation: mutation, logoutMutation: .logout)
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setViewDidLoad:
            newState.isViewLoaded = true

        case .setLoading(let isLoading):
            newState.isLoading = isLoading
            newState.errorMessage = nil

        case .setStores(let response):
            newState.isLoading = false
            newState.stores = response.data
            newState.nextCursor = response.nextCursor
            newState.errorMessage = nil

        case .setError(let error):
            newState.isLoading = false
            newState.errorMessage = error.localizedDescription

        case .logout:
            newState.shouldNavigateToLogin = true

        case .toggleLikeState(let index):
            guard index >= 0 && index < newState.stores.count else { break }
            newState.stores[index].isPicchelin.toggle()
        }

        return newState
    }
}
