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
        case selectBrand(index: Int, storeId: String)
    }

    enum Mutation {
        case setViewDidLoad
        case setLoading(Bool)
        case setStores(stores: [StoreEntity], nextCursor: String)
        case setBanners(BannerResponseDTO)
        case setError(Error)
        case setMenuList([StoreDetailEntity.Menu])
        case setSelectedBrandIndex(Int)
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
        var selectedBrandIndex: Int = 0
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

                    // 위치 정보 가져오기
                    let location = await LocationManager.shared.getCurrentLocation()
                    print("📍 [Location] Using coordinates: \(location.latitude), \(location.longitude)")

                    async let storesResult = self.storeRepository.fetchStores(
                        category: "Modern",
                        longitude: location.longitude,
                        latitude: location.latitude,
                        orderBy: .distance
                    )
                    async let bannersResponse = self.storeRepository.fetchBanners()

                    let (stores, banners) = try await (storesResult, bannersResponse)

                    print("✅ [API] Stores received: \(stores.stores.count) items")
                    print("✅ [API] Banners received: \(banners.data.count) items")
                    send(.setStores(stores: stores.stores, nextCursor: stores.nextCursor))

                    // 첫 번째 브랜드의 메뉴 로드
                    if !stores.stores.isEmpty {
                        let storeDetail = try await self.storeRepository.fetchStoreDetail(storeId: stores.stores[0].storeId)
                        send(.setMenuList(storeDetail.menuList))
                        send(.setSelectedBrandIndex(0))
                    }

                    send(.setBanners(banners))
                },
                onError: { error in
                    print("❌ [API] HomeReactor error: \(error.localizedDescription)")
                    return .setError(error)
                }
            )

        case .selectBrand(let index, let storeId):
            return run(
                operation: { [weak self] send in
                    guard let self else { return }

                    print("📡 [API] Fetching menu for store: \(storeId)")
                    send(.setSelectedBrandIndex(index))

                    let storeDetail = try await self.storeRepository.fetchStoreDetail(storeId: storeId)
                    send(.setMenuList(storeDetail.menuList))
                    print("✅ [API] Menu received: \(storeDetail.menuList.count) items")
                },
                onError: { error in
                    print("❌ [API] Menu fetch error: \(error.localizedDescription)")
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

        case .setSelectedBrandIndex(let index):
            newState.selectedBrandIndex = index

        case .logout:
            newState.shouldNavigateToLogin = true
        }

        return newState
    }
}
