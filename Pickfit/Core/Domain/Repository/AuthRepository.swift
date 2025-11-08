//
//  AuthRepository.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation

final class AuthRepository {
    private let tokenStorage: AuthTokenStorage

    init(tokenStorage: AuthTokenStorage = KeychainAuthStorage.shared) {
        self.tokenStorage = tokenStorage
    }

    func loginWithKakao(oauthToken: String) async throws {
        // UserDefaults에서 FCM 토큰 가져오기 (AppDelegate에서 저장했음)
        let deviceToken = UserDefaults.standard.string(forKey: "deviceToken")
        print("📤 [AuthRepository] Kakao Login with FCM Token: \(deviceToken ?? "none")")

        let dto = try await NetworkManager.auth.fetch(
            dto: KakaoResponseDTO.self,
            router: LoginRouter.kakaoLogin(KakaoRequestDTO(
                oauthToken: oauthToken,
                deviceToken: deviceToken  // FCM 토큰 추가
            ))
        )

        tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)
        tokenStorage.writeUserId(dto.userId)

        print("✅ [AuthRepository] Kakao Login Success - userId: \(dto.userId)")
    }

    func loginWithApple(identityToken: String, nickname: String?) async throws {
        print("📡 [AuthRepository] Apple Login Request")
        print("   - idToken: \(identityToken.prefix(20))...")
        print("   - nick: \(nickname ?? "nil")")

        // UserDefaults에서 FCM 토큰 가져오기 (AppDelegate에서 저장했음)
        let deviceToken = UserDefaults.standard.string(forKey: "deviceToken")
        print("📤 [AuthRepository] Apple Login with deviceToken: \(deviceToken ?? "none")")

        let requestDTO = AppleRequestDTO(
            idToken: identityToken,
            nick: nickname,
            deviceToken: deviceToken  // FCM 토큰 추가
        )

        // JSON 확인용 디버깅
        if let jsonData = try? JSONEncoder().encode(requestDTO),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 [AuthRepository] Request JSON: \(jsonString)")
        }

        let dto = try await NetworkManager.auth.fetch(
            dto: KakaoResponseDTO.self,  // 애플 로그인도 같은 응답 형식 사용
            router: LoginRouter.appleLogin(requestDTO)
        )

        tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)
        tokenStorage.writeUserId(dto.userId)

        print("✅ [AuthRepository] Apple Login Success - userId: \(dto.userId)")
    }

    func loginWithEmail(email: String, password: String) async throws {
        let deviceToken = UserDefaults.standard.string(forKey: "deviceToken")
        print("📤 [AuthRepository] Email Login with FCM Token: \(deviceToken ?? "none")")

        let dto = try await NetworkManager.auth.fetch(
            dto: KakaoResponseDTO.self,  // 응답 형식 동일
            router: LoginRouter.emailLogin(EmailLoginRequestDTO(
                email: email,
                password: password,
                deviceToken: deviceToken
            ))
        )

        tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)
        tokenStorage.writeUserId(dto.userId)

        print("✅ [AuthRepository] Email Login Success - userId: \(dto.userId)")
    }

    func signUp(email: String, password: String, nick: String, phoneNum: String) async throws {
        let deviceToken = UserDefaults.standard.string(forKey: "deviceToken")
        print("📤 [AuthRepository] SignUp Request - email: \(email), nick: \(nick)")

        let dto = try await NetworkManager.auth.fetch(
            dto: KakaoResponseDTO.self,  // 회원가입도 응답 형식 동일
            router: LoginRouter.signUp(SignUpRequestDTO(
                email: email,
                password: password,
                nick: nick,
                phoneNum: phoneNum,
                deviceToken: deviceToken
            ))
        )

        tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)
        tokenStorage.writeUserId(dto.userId)

        print("✅ [AuthRepository] SignUp Success - userId: \(dto.userId), nick: \(dto.nick)")
    }

    func validateEmail(_ email: String) async throws -> String {
        print("📤 [AuthRepository] Email Validation Request - email: \(email)")

        let dto = try await NetworkManager.auth.fetch(
            dto: EmailValidationResponseDTO.self,
            router: LoginRouter.validateEmail(EmailValidationRequestDTO(email: email))
        )

        print("✅ [AuthRepository] Email Validation Success - message: \(dto.message)")
        return dto.message
    }

    func refreshToken() async throws -> (accessToken: String, refreshToken: String) {
        guard let refreshToken = tokenStorage.readRefresh(),
              let accessToken = tokenStorage.readAccess() else {
            throw NSError(domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token이 없습니다"])
        }

        let dto = try await NetworkManager.auth.fetch(
            dto: RefreshTokenResponseDTO.self,
            router: LoginRouter.refreshToken(RefreshTokenRequestDTO(
                accessToken: accessToken,
                refreshToken: refreshToken
            ))
        )

        tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)

        return (accessToken: dto.accessToken, refreshToken: dto.refreshToken)
    }
}
