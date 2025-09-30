//
//  HomeReactor.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import ReactorKit
import RxSwift

final class HomeReactor: Reactor {

    enum Action {
        case viewDidLoad
    }

    enum Mutation {
        case setViewDidLoad
        case logout
    }

    struct State {
        var isViewLoaded: Bool = false
        var shouldNavigateToLogin: Bool = false
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return Observable.just(.setViewDidLoad)
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

        case .logout:
            newState.shouldNavigateToLogin = true
        }

        return newState
    }
}