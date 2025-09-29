//
//  AuthRepository.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation

final class AuthRepository {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager = NetworkManager()) {
        self.networkManager = networkManager
    }

    func loginWithKakao(oauthToken: String) async throws -> AuthEntity {
        let dto = try await networkManager.fetch(
            dto: KakaoResponseDTO.self,
            router: LoginRouter.kakaoLogin(KakaoRequestDTO(oauthToken: oauthToken))
        )

        return AuthMapper.dtoToEntity(dto)
    }
}