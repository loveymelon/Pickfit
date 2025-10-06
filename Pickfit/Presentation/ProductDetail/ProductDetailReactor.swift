//
//  ProductDetailReactor.swift
//  Pickfit
//
//  Created by 김진수 on 10/6/25.
//

import RxSwift
import ReactorKit

final class ProductDetailReactor: Reactor {
    enum Action {
        case viewDidLoad
    }

    enum Mutation {
        case setViewDidLoad
    }

    struct State {
        var isViewLoaded: Bool = false
        var menus: [StoreDetailEntity.Menu] = []
        var imageUrls: [String] = []
    }

    var initialState: State

    init(menus: [StoreDetailEntity.Menu]) {
        let imageUrls = menus.map { $0.menuImageUrl }
        self.initialState = State(menus: menus, imageUrls: imageUrls)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.just(.setViewDidLoad)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setViewDidLoad:
            newState.isViewLoaded = true
        }

        return newState
    }
}
