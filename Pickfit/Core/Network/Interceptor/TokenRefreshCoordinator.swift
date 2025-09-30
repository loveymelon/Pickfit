//
//  TokenRefreshCoordinator.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import Foundation

actor TokenRefreshCoordinator {
    private var isRefreshing = false
    private var waitingRequests: [CheckedContinuation<String, Error>] = []

    func refresh(using refreshLogic: @Sendable () async throws -> String) async throws -> String {
        // 이미 갱신 중이면 대기
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                waitingRequests.append(continuation)
            }
        }

        // 갱신 시작
        isRefreshing = true

        do {
            let newToken = try await refreshLogic()
            isRefreshing = false

            // 대기 중인 요청들에게 새 토큰 전달
            waitingRequests.forEach { $0.resume(returning: newToken) }
            waitingRequests.removeAll()

            return newToken
        } catch {
            isRefreshing = false

            // 대기 중인 요청들에게 에러 전달
            waitingRequests.forEach { $0.resume(throwing: error) }
            waitingRequests.removeAll()

            throw error
        }
    }
}