//
//  LoginManager.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import KakaoSDKAuth
import KakaoSDKUser
import AuthenticationServices

struct LoginManager {
    func kakaoLogin() async throws -> String {
        if UserApi.isKakaoTalkLoginAvailable() {
            return try await loginWithApp()
        } else {
            return try await loginWithAccount()
        }
    }

    /// 애플 로그인
    /// - Returns: (identityToken, nickname) 튜플
    @MainActor
    func appleLogin() async throws -> (token: String, nickname: String?) {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate()
        controller.delegate = delegate
        controller.performRequests()

        return try await delegate.waitForResult()
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

// MARK: - Apple Sign In Delegate

@MainActor
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private var continuation: CheckedContinuation<(token: String, nickname: String?), Error>?

    func waitForResult() async throws -> (token: String, nickname: String?) {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignIn",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get identity token"]
            ))
            return
        }

        // nickname 추출 (최초 로그인 시에만 제공됨)
        var nickname: String?
        if let fullName = credential.fullName {
            let components = [fullName.familyName, fullName.givenName]
                .compactMap { $0 }
            if !components.isEmpty {
                nickname = components.joined(separator: " ")
            }
        }

        print("✅ [AppleSignIn] Success")
        print("   - userIdentifier: \(credential.user)")
        print("   - nickname: \(nickname ?? "nil")")
        print("   - email: \(credential.email ?? "nil")")

        continuation?.resume(returning: (token: tokenString, nickname: nickname))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("❌ [AppleSignIn] Error: \(error.localizedDescription)")
        continuation?.resume(throwing: error)
    }
}
