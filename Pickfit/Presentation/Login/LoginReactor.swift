//
//  LoginReactor.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import ReactorKit
import RxSwift

final class LoginReactor: Reactor {

    private let loginManager: LoginManager

    init(loginManager: LoginManager = LoginManager()) {
        self.loginManager = loginManager
    }

    enum Action {
        case loginButtonTapped
    }

    enum Mutation {
        case setLoading(Bool)
        case setLoginSuccess(String)
        case setLoginFailure(Error)
    }

    struct State {
        var isLoading: Bool = false
        var isLoginSucceed: Bool? = nil
        var accessToken: String? = nil
        var errorMessage: String? = nil
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loginButtonTapped:
            return run(
                operation: { send in
                    send(.setLoading(true))
                    let accessToken = try await self.loginManager.kakaoLogin()
                    send(.setLoginSuccess(accessToken))
                },
                onError: { error in
                    .setLoginFailure(error)
                }
            )
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
            newState.errorMessage = nil

        case .setLoginSuccess(let accessToken):
            newState.isLoading = false
            newState.isLoginSucceed = true
            newState.accessToken = accessToken
            newState.errorMessage = nil

        case .setLoginFailure(let error):
            newState.isLoading = false
            newState.isLoginSucceed = false
            newState.accessToken = nil
            newState.errorMessage = error.localizedDescription
        }

        return newState
    }
}
