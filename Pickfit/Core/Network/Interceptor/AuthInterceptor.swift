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
        var request = urlRequest
        let requestPath = urlRequest.url?.path ?? "unknown"
        let requestMethod = urlRequest.httpMethod ?? "unknown"

        // AccessToken을 헤더에 추가
        if let accessToken = tokenStorage.readAccess() {
            print("🔐 [Auth Adapt] \(requestMethod) \(requestPath)")
            print("   ✅ Token exists: \(accessToken.prefix(30))...")
            print("   📋 Headers before: \(request.allHTTPHeaderFields ?? [:])")
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
            print("   📋 Headers after: \(request.allHTTPHeaderFields ?? [:])")
        } else {
            print("🔐 [Auth Adapt] \(requestMethod) \(requestPath)")
            print("   ⚠️ No token available")
        }

        completion(.success(request))
    }

    // MARK: - RequestRetrier
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        let requestPath = request.request?.url?.path ?? "unknown"
        let requestMethod = request.request?.httpMethod ?? "unknown"

        print("🔄 [Auth Retry] \(requestMethod) \(requestPath)")
        print("   🔍 Error: \(error.localizedDescription)")

        guard let response = request.task?.response as? HTTPURLResponse else {
            print("   ⚠️ No HTTP response - Do not retry")
            completion(.doNotRetry)
            return
        }

        let statusCode = response.statusCode
        print("   📊 Status Code: \(statusCode)")

        Task {
            switch statusCode {
            case 419:
                print("   ❌ 419 - Token expired")
                // AccessToken 만료 → RefreshToken으로 갱신 후 재시도
                do {
                    print("   🔄 Starting token refresh...")
                    _ = try await TokenRefreshCoordinator.shared.refresh {
                        try await self.refreshTokens()
                    }
                    print("   ✅ Token refresh successful - Retrying request")
                    completion(.retry)
                } catch {
                    print("   ❌ Token refresh failed: \(error.localizedDescription)")
                    print("   🗑️ Clearing tokens...")
                    // RefreshToken 갱신 실패 → 토큰 삭제 후 에러 전파
                    self.tokenStorage.clear()
                    completion(.doNotRetry)
                }

            case 401, 403, 418:
                print("   ❌ \(statusCode) - Auth failed (Critical)")
                print("   🗑️ Clearing tokens...")
                // 인증 불가능 또는 RefreshToken 만료 → 토큰 삭제 후 에러 전파
                self.tokenStorage.clear()
                completion(.doNotRetry)

            default:
                print("   ❌ \(statusCode) - Request failed (Not auth related)")
                // 기타 에러는 재시도 안함
                completion(.doNotRetry)
            }
        }
    }

    // MARK: - Private Methods
    private func refreshTokens() async throws -> String {
        guard let refreshToken = tokenStorage.readRefresh(),
              let accessToken = tokenStorage.readAccess() else {
            print("❌ [Refresh] No tokens available")
            throw NSError(domain: "AuthInterceptor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token이 없습니다"])
        }

        print("🔄 [Refresh] Calling refresh token API")
        print("🔍 [Refresh] AccessToken: \(accessToken.prefix(20))...")
        print("🔍 [Refresh] RefreshToken: \(refreshToken.prefix(20))...")

        let router = LoginRouter.refreshToken(RefreshTokenRequestDTO(
            accessToken: accessToken,
            refreshToken: refreshToken
        ))
        let request = try router.asURLRequest()
        print("🔍 [Refresh] Request URL: \(request.url?.absoluteString ?? "nil")")
        print("🔍 [Refresh] Request Headers: \(request.allHTTPHeaderFields ?? [:])")

        let dto = try await NetworkManager.auth.fetch(
            dto: RefreshTokenResponseDTO.self,
            router: router
        )

        print("✅ [Refresh] New tokens received - Saving to storage")
        print("✅ [Refresh] New access token: \(dto.accessToken.prefix(20))...")
        // 새 토큰 저장
        tokenStorage.write(access: dto.accessToken, refresh: dto.refreshToken)

        return dto.accessToken
    }
}