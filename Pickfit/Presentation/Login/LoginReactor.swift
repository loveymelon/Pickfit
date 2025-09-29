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
        case setLoginSuccess
        case setLoginFailure(Error)
    }

    struct State {
        var isLoading: Bool = false
        var isLoginSucceed: Bool = false
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
                    // 2. 서버 로그인 및 토큰 저장 (Repository에서 처리)
                    try await self.authRepository.loginWithKakao(oauthToken: kakaoToken)
                    send(.setLoginSuccess)
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

        case .setLoginSuccess:
            newState.isLoading = false
            newState.isLoginSucceed = true
            newState.errorMessage = nil

        case .setLoginFailure(let error):
            newState.isLoading = false
            newState.isLoginSucceed = false
            newState.errorMessage = error.localizedDescription
        }

        return newState
    }
}
