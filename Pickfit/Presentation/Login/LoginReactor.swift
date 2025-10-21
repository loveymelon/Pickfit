//
//  LoginReactor.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import ReactorKit
import RxSwift
import FirebaseMessaging

final class LoginReactor: Reactor {

    private let loginManager: LoginManager
    private let authRepository: AuthRepository
    private let notificationRepository: NotificationRepository

    init(loginManager: LoginManager = LoginManager(),
         authRepository: AuthRepository = AuthRepository(),
         notificationRepository: NotificationRepository = NotificationRepository()) {
        self.loginManager = loginManager
        self.authRepository = authRepository
        self.notificationRepository = notificationRepository
    }

    enum Action {
        case kakaoLoginButtonTapped
        case appleLoginButtonTapped
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
        case .kakaoLoginButtonTapped:
            return run(
                operation: { send in
                    send(.setLoading(true))
                    // 1. 카카오 토큰 획득
                    let kakaoToken = try await self.loginManager.kakaoLogin()
                    // 2. 서버 로그인 및 토큰 저장 (Repository에서 처리)
                    try await self.authRepository.loginWithKakao(oauthToken: kakaoToken)
                    // 3. 로그인 성공 후 최신 FCM 토큰 업데이트
                    try await self.updateFCMTokenIfNeeded()
                    send(.setLoginSuccess)
                },
                onError: { error in
                    .setLoginFailure(error)
                }
            )

        case .appleLoginButtonTapped:
            return run(
                operation: { send in
                    send(.setLoading(true))
                    // 1. 애플 identityToken과 nickname 획득
                    let (identityToken, nickname) = try await self.loginManager.appleLogin()
                    // 2. 서버 로그인 및 토큰 저장 (Repository에서 처리)
                    try await self.authRepository.loginWithApple(
                        identityToken: identityToken,
                        nickname: nickname
                    )
                    // 3. 로그인 성공 후 최신 FCM 토큰 업데이트
                    try await self.updateFCMTokenIfNeeded()
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

    // MARK: - Private Methods

    /// 로그인 성공 후 최신 FCM 토큰을 서버에 업데이트
    /// - Note: Firebase에서 토큰을 가져와서 서버에 전송
    private func updateFCMTokenIfNeeded() async throws {
        print("🔄 [LoginReactor] Updating FCM token after login...")

        // Firebase에서 최신 FCM 토큰 가져오기
        guard let fcmToken = await getFCMToken() else {
            print("⚠️ [LoginReactor] No FCM token available, skip update")
            return
        }

        print("📤 [LoginReactor] Sending FCM token to server: \(fcmToken.prefix(30))...")

        do {
            try await notificationRepository.updateDeviceToken(fcmToken)
            print("✅ [LoginReactor] FCM token updated successfully")

            // UserDefaults에도 저장 (다음 비교를 위해)
            UserDefaults.standard.set(fcmToken, forKey: "deviceToken")
        } catch {
            print("❌ [LoginReactor] Failed to update FCM token: \(error.localizedDescription)")
            // 실패해도 로그인은 성공으로 처리 (푸시만 안 오는 것)
        }
    }

    /// Firebase에서 FCM 토큰 가져오기
    /// - Returns: FCM 토큰 (없으면 nil)
    private func getFCMToken() async -> String? {
        return await withCheckedContinuation { continuation in
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("❌ [LoginReactor] Failed to get FCM token: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: token)
                }
            }
        }
    }
}
