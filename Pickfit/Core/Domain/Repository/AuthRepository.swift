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
        let dto = try await NetworkManager.auth.fetch(
            dto: KakaoResponseDTO.self,
            router: LoginRouter.kakaoLogin(KakaoRequestDTO(oauthToken: oauthToken))
        )

        await tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)
        await tokenStorage.writeUserId(dto.userId)
    }

    func loginWithApple(identityToken: String, nickname: String?) async throws {
        print("📡 [AuthRepository] Apple Login Request")
        print("   - idToken: \(identityToken.prefix(20))...")
        print("   - nick: \(nickname ?? "nil")")

        // deviceToken은 선택사항 - 푸시 알림용 (추후 구현 시 추가)
        let requestDTO = AppleRequestDTO(
            idToken: identityToken,
            nick: nickname,
            deviceToken: nil
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

        await tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)
        await tokenStorage.writeUserId(dto.userId)

        print("✅ [AuthRepository] Apple Login Success - userId: \(dto.userId)")
    }

    func refreshToken() async throws -> (accessToken: String, refreshToken: String) {
        guard let refreshToken = await tokenStorage.readRefresh(),
              let accessToken = await tokenStorage.readAccess() else {
            throw NSError(domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token이 없습니다"])
        }

        let dto = try await NetworkManager.auth.fetch(
            dto: RefreshTokenResponseDTO.self,
            router: LoginRouter.refreshToken(RefreshTokenRequestDTO(
                accessToken: accessToken,
                refreshToken: refreshToken
            ))
        )

        await tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)

        return (accessToken: dto.accessToken, refreshToken: dto.refreshToken)
    }
}
