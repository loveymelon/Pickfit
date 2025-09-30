//
//  AuthRepository.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation

final class AuthRepository {
    private let networkManager: NetworkManager
    private let authNetworkManager: NetworkManager
    private let tokenStorage: AuthTokenStorage

    init(networkManager: NetworkManager = NetworkManager(),
         tokenStorage: AuthTokenStorage = KeychainAuthStorage()) {
        self.networkManager = networkManager
        self.authNetworkManager = NetworkManager()
        self.tokenStorage = tokenStorage
    }

    func loginWithKakao(oauthToken: String) async throws {
        let dto = try await authNetworkManager.fetch(
            dto: KakaoResponseDTO.self,
            router: LoginRouter.kakaoLogin(KakaoRequestDTO(oauthToken: oauthToken))
        )

        await tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)
    }

    func refreshToken() async throws -> (accessToken: String, refreshToken: String) {
        guard let refreshToken = await tokenStorage.readRefresh() else {
            throw NSError(domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "RefreshToken이 없습니다"])
        }

        let dto = try await authNetworkManager.fetch(
            dto: RefreshTokenResponseDTO.self,
            router: LoginRouter.refreshToken(RefreshTokenRequestDTO(refreshToken: refreshToken))
        )

        await tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)

        return (accessToken: dto.accessToken, refreshToken: dto.refreshToken)
    }
}
