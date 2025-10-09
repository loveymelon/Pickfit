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
