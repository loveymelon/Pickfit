//
//  AuthRepository.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation

final class AuthRepository {
    private let networkManager: NetworkManager
    private let tokenStorage: AuthTokenStorage

    init(networkManager: NetworkManager = NetworkManager(),
         tokenStorage: AuthTokenStorage = KeychainAuthStorage()) {
        self.networkManager = networkManager
        self.tokenStorage = tokenStorage
    }

    func loginWithKakao(oauthToken: String) async throws {
        let dto = try await networkManager.fetch(
            dto: KakaoResponseDTO.self,
            router: LoginRouter.kakaoLogin(KakaoRequestDTO(oauthToken: oauthToken))
        )

        await tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)
    }
}
