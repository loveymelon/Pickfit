//
//  AuthInterceptor.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import Foundation
import Alamofire

final class AuthInterceptor: RequestInterceptor {
    private let tokenStorage: AuthTokenStorage
    private let refreshCoordinator: TokenRefreshCoordinator
    private let onLogout: @Sendable () -> Void

    init(
        tokenStorage: AuthTokenStorage = KeychainAuthStorage(),
        onLogout: @escaping @Sendable () -> Void
    ) {
        self.tokenStorage = tokenStorage
        self.refreshCoordinator = TokenRefreshCoordinator()
        self.onLogout = onLogout
    }

    // MARK: - RequestAdapter
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        Task {
            var request = urlRequest

            // AccessToken을 헤더에 추가
            if let accessToken = await tokenStorage.readAccess() {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }

            completion(.success(request))
        }
    }

    // MARK: - RequestRetrier
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse else {
            completion(.doNotRetry)
            return
        }

        let statusCode = response.statusCode

        Task {
            switch statusCode {
            case 419:
                // AccessToken 만료 → RefreshToken으로 갱신 후 재시도
                do {
                    _ = try await refreshCoordinator.refresh {
                        try await self.refreshTokens()
                    }
                    completion(.retry)
                } catch {
                    // RefreshToken 갱신 실패 → 로그아웃
                    await handleLogout()
                    completion(.doNotRetry)
                }

            case 401, 418:
                // 인증 불가능 또는 RefreshToken 만료 → 로그아웃
                await handleLogout()
                completion(.doNotRetry)

            default:
                // 기타 에러는 재시도 안함
                completion(.doNotRetry)
            }
        }
    }

    // MARK: - Private Methods
    private func refreshTokens() async throws -> String {
        guard let refreshToken = await tokenStorage.readRefresh() else {
            throw NSError(domain: "AuthInterceptor", code: -1, userInfo: [NSLocalizedDescriptionKey: "RefreshToken이 없습니다"])
        }

        let networkManager = NetworkManager()
        let dto = try await networkManager.fetch(
            dto: RefreshTokenResponseDTO.self,
            router: LoginRouter.refreshToken(RefreshTokenRequestDTO(refreshToken: refreshToken))
        )

        // 새 토큰 저장
        await tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)

        return dto.accessToken
    }

    private func handleLogout() async {
        await tokenStorage.clear()
        await MainActor.run {
            onLogout()
        }
    }
}