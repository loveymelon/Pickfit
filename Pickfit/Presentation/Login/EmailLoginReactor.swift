//
//  EmailLoginReactor.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import Foundation
import ReactorKit
import RxSwift

final class EmailLoginReactor: Reactor {

    private let authRepository: AuthRepository
    private let notificationRepository: NotificationRepository

    init(
        authRepository: AuthRepository = AuthRepository(),
        notificationRepository: NotificationRepository = NotificationRepository()
    ) {
        self.authRepository = authRepository
        self.notificationRepository = notificationRepository
    }

    enum Action {
        case emailChanged(String)
        case passwordChanged(String)
        case loginButtonTapped
    }

    enum Mutation {
        case setEmail(String)
        case setPassword(String)
        case setLoading(Bool)
        case setLoginSuccess
        case setError(String)
    }

    struct State {
        var email: String = ""
        var password: String = ""
        var isLoading: Bool = false
        var isLoginSucceed: Bool = false
        var errorMessage: String? = nil

        var isFormValid: Bool {
            return !email.isEmpty && !password.isEmpty
        }
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .emailChanged(let email):
            return Observable.just(.setEmail(email))

        case .passwordChanged(let password):
            return Observable.just(.setPassword(password))

        case .loginButtonTapped:
            return run(
                operation: { [weak self] send in
                    guard let self else { return }
                    let state = self.currentState

                    send(.setLoading(true))

                    // 유효성 검사
                    guard !state.email.isEmpty, !state.password.isEmpty else {
                        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "이메일과 비밀번호를 입력해주세요."])
                    }

                    // 로그인 API
                    try await self.authRepository.loginWithEmail(
                        email: state.email,
                        password: state.password
                    )

                    // FCM 토큰 업데이트
                    try await self.updateFCMTokenIfNeeded()

                    send(.setLoginSuccess)
                    send(.setLoading(false))
                },
                onError: { error in
                    return .setError(error.localizedDescription)
                }
            ).flatMap { mutation -> Observable<Mutation> in
                if case .setError = mutation {
                    return Observable.concat([
                        .just(mutation),
                        .just(.setLoading(false))
                    ])
                }
                return .just(mutation)
            }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setEmail(let email):
            newState.email = email
            newState.errorMessage = nil

        case .setPassword(let password):
            newState.password = password
            newState.errorMessage = nil

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setLoginSuccess:
            newState.isLoginSucceed = true
            newState.errorMessage = nil

        case .setError(let error):
            newState.errorMessage = error
            newState.isLoading = false
        }

        return newState
    }

    // MARK: - Private Methods

    private func updateFCMTokenIfNeeded() async throws {
        guard let fcmToken = await getFCMToken() else {
            print("⚠️ [EmailLoginReactor] FCM Token not available")
            return
        }

        let cachedToken = UserDefaults.standard.string(forKey: "deviceToken")

        if fcmToken != cachedToken {
            print("🔄 [EmailLoginReactor] Updating FCM Token to server")
            try await notificationRepository.updateDeviceToken(fcmToken)
            UserDefaults.standard.set(fcmToken, forKey: "deviceToken")
        } else {
            print("ℹ️ [EmailLoginReactor] FCM Token already up to date")
        }
    }

    @MainActor
    private func getFCMToken() async -> String? {
        return await withCheckedContinuation { continuation in
            #if canImport(FirebaseMessaging)
            // FirebaseMessaging이 있으면 토큰 가져오기
            continuation.resume(returning: UserDefaults.standard.string(forKey: "deviceToken"))
            #else
            continuation.resume(returning: nil)
            #endif
        }
    }
}
