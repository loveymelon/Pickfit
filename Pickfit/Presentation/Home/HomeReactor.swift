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
        case setStores(stores: [StoreEntity], nextCursor: String)
        case setBanners(BannerResponseDTO)
        case setError(Error)
        case setMenuList([StoreDetailEntity.Menu])
        case logout
    }

    struct State {
        var isViewLoaded: Bool = false
        var isLoading: Bool = false
        var stores: [StoreEntity] = []
        var categories: [Category] = Category.allCases
        var banners: [BannerResponseDTO.Banner] = []
        var nextCursor: String = ""
        var errorMessage: String? = nil
        var shouldNavigateToLogin: Bool = false
        var menuList: [StoreDetailEntity.Menu] = []
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.just(.setViewDidLoad)

        case .viewIsAppearing:
            return run(
                operation: { [weak self] send in
                    guard let self else { return }
                    
                    print("📡 [API] HomeReactor - Starting API calls")
                    send(.setLoading(true))

                    async let storesResult = self.storeRepository.fetchStores(
                        category: "Modern",
                        longitude: 127.0,
                        latitude: 37.5,
                        orderBy: .distance
                    )
                    async let bannersResponse = self.storeRepository.fetchBanners()

                    let (stores, banners) = try await (storesResult, bannersResponse)

                    print("✅ [API] Stores received: \(stores.stores.count) items")
                    print("✅ [API] Banners received: \(banners.data.count) items")
                    send(.setStores(stores: stores.stores, nextCursor: stores.nextCursor))
                    
                    let storeDetail = try await self.storeRepository.fetchStoreDetail(storeId: stores.stores[0].storeId)
                    
                    send(.setMenuList(storeDetail.menuList))
                    //                    await self.storeRepository.fetchStoreDetail(storeId: <#T##String#>)
                    
                    send(.setBanners(banners))
                },
                onError: { error in
                    print("❌ [API] HomeReactor error: \(error.localizedDescription)")
                    return .setError(error)
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

        case .setStores(let stores, let nextCursor):
            newState.isLoading = false
            newState.stores = stores
            newState.nextCursor = nextCursor
            newState.errorMessage = nil

        case .setBanners(let response):
            newState.banners = response.data

        case .setError(let error):
            newState.isLoading = false
            newState.errorMessage = error.localizedDescription
            
        case .setMenuList(let menu):
            newState.menuList = menu

        case .logout:
            newState.shouldNavigateToLogin = true
        }

        return newState
    }
}
