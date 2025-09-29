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
    private let authRepository: AuthRepository

    init(loginManager: LoginManager = LoginManager(),
         authRepository: AuthRepository = AuthRepository()) {
        self.loginManager = loginManager
        self.authRepository = authRepository
    }

    enum Action {
        case loginButtonTapped
    }

    enum Mutation {
        case setLoading(Bool)
        case setLoginSuccess(AuthEntity)
        case setLoginFailure(Error)
    }

    struct State {
        var isLoading: Bool = false
        var isLoginSucceed: Bool? = nil
        var authEntity: AuthEntity? = nil
        var errorMessage: String? = nil
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loginButtonTapped:
            return run(
                operation: { send in
                    send(.setLoading(true))
                    // 1. 카카오 토큰 획득
                    let kakaoToken = try await self.loginManager.kakaoLogin()
                    // 2. 서버 로그인
                    let authEntity = try await self.authRepository.loginWithKakao(oauthToken: kakaoToken)
                    send(.setLoginSuccess(authEntity))
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

        case .setLoginSuccess(let authEntity):
            newState.isLoading = false
            newState.isLoginSucceed = true
            newState.authEntity = authEntity
            newState.errorMessage = nil

        case .setLoginFailure(let error):
            newState.isLoading = false
            newState.isLoginSucceed = false
            newState.authEntity = nil
            newState.errorMessage = error.localizedDescription
        }

        return newState
    }
}
