//
//  LoginManager.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import KakaoSDKAuth
import KakaoSDKUser

struct LoginManager {
    func kakaoLogin() async throws -> String {
        if UserApi.isKakaoTalkLoginAvailable() {
            return try await loginWithApp()
        } else {
            return try await loginWithAccount()
        }
    }
}

private extension LoginManager {
    func loginWithApp() async throws -> String {
        try await bridge { completion in
            UserApi.shared.loginWithKakaoTalk(completion: completion)
        }
    }
    
    func loginWithAccount() async throws -> String {
        try await bridge { completion in
            UserApi.shared.loginWithKakaoAccount(completion: completion)
        }
    }

    @MainActor
    func bridge(_ perform: (@escaping (OAuthToken?, Error?) -> Void) -> Void) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            perform { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token {
                    continuation.resume(returning: token.accessToken)
                }
            }
        }
    }
}
