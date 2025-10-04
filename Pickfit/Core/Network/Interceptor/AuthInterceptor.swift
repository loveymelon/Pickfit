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

    init(tokenStorage: AuthTokenStorage = KeychainAuthStorage.shared) {
        self.tokenStorage = tokenStorage
    }

    // MARK: - RequestAdapter
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        Task {
            var request = urlRequest

            // AccessToken을 헤더에 추가
            if let accessToken = await tokenStorage.readAccess() {
                print("🔐 [Auth] Request: \(urlRequest.url?.path ?? "unknown") - Token exists")
                request.setValue(accessToken, forHTTPHeaderField: "Authorization")
            } else {
                print("🔐 [Auth] Request: \(urlRequest.url?.path ?? "unknown") - No token")
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
                print("❌ [Error] 419 - Token expired for: \(request.request?.url?.path ?? "unknown")")
                // AccessToken 만료 → RefreshToken으로 갱신 후 재시도
                do {
                    print("🔄 [Refresh] Starting token refresh...")
                    _ = try await TokenRefreshCoordinator.shared.refresh {
                        try await self.refreshTokens()
                    }
                    print("✅ [Refresh] Token refresh successful - Retrying request")
                    completion(.retry)
                } catch {
                    print("❌ [Refresh] Token refresh failed: \(error.localizedDescription)")
                    // RefreshToken 갱신 실패 → 토큰 삭제 후 에러 전파
                    await tokenStorage.clear()
                    completion(.doNotRetry)
                }

            case 401, 403, 418:
                print("❌ [Error] \(statusCode) - Auth failed for: \(request.request?.url?.path ?? "unknown")")
                // 인증 불가능 또는 RefreshToken 만료 → 토큰 삭제 후 에러 전파
                await tokenStorage.clear()
                completion(.doNotRetry)

            default:
                print("❌ [Error] \(statusCode) - Request failed: \(request.request?.url?.path ?? "unknown")")
                // 기타 에러는 재시도 안함
                completion(.doNotRetry)
            }
        }
    }

    // MARK: - Private Methods
    private func refreshTokens() async throws -> String {
        guard let refreshToken = await tokenStorage.readRefresh() else {
            print("❌ [Refresh] No refresh token available")
            throw NSError(domain: "AuthInterceptor", code: -1, userInfo: [NSLocalizedDescriptionKey: "RefreshToken이 없습니다"])
        }

        print("🔄 [Refresh] Calling refresh token API with token: \(refreshToken.prefix(20))...")
        let dto = try await NetworkManager.auth.fetch(
            dto: RefreshTokenResponseDTO.self,
            router: LoginRouter.refreshToken(RefreshTokenRequestDTO(refreshToken: refreshToken))
        )

        print("✅ [Refresh] New tokens received - Saving to storage")
        print("✅ [Refresh] New access token: \(dto.accessToken.prefix(20))...")
        // 새 토큰 저장
        await tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)

        return dto.accessToken
    }
}