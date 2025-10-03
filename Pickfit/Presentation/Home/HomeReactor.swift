//
//  HomeReactor.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import ReactorKit
import RxSwift

final class HomeReactor: Reactor {

    private let storeRepository: StoreRepository

    init(storeRepository: StoreRepository = StoreRepository()) {
        self.storeRepository = storeRepository
    }

    enum Action {
        case viewDidLoad
        case viewIsAppearing
    }

    enum Mutation {
        case setViewDidLoad
        case setLoading(Bool)
        case setStores(StoreResponseDTO)
        case setBanners(BannerResponseDTO)
        case setError(Error)
        case logout
    }

    struct State {
        var isViewLoaded: Bool = false
        var isLoading: Bool = false
        var stores: [StoreResponseDTO.Store] = []
        var categories: [Category] = Category.allCases
        var banners: [BannerResponseDTO.Banner] = []
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
                    send(.setLoading(true))

                    async let storesResponse = self.storeRepository.fetchStores(
                        category: "Sport",
                        longitude: 127.0,
                        latitude: 37.5,
                        orderBy: .distance
                    )
                    async let bannersResponse = self.storeRepository.fetchBanners()

                    let (stores, banners) = try await (storesResponse, bannersResponse)

                    send(.setStores(stores))
                    send(.setBanners(banners))
                },
                onError: { error in
                    .setError(error)
                }
            )
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

        case .setBanners(let response):
            newState.banners = response.data

        case .setError(let error):
            newState.isLoading = false
            newState.errorMessage = error.localizedDescription

        case .logout:
            newState.shouldNavigateToLogin = true
        }

        return newState
    }
}
