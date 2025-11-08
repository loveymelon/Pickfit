//
//  NotificationRepository.swift
//  Pickfit
//
//  Created by 김진수 on 10/19/25.
//

import Foundation

/// 푸시 알림 관련 API 호출을 담당하는 Repository
final class NotificationRepository {

    /// 푸시 알림 테스트 전송
    /// - Parameters:
    ///   - userId: 수신자 사용자 ID
    ///   - title: 알림 제목
    ///   - subtitle: 알림 부제목
    ///   - body: 알림 본문
    /// - Note: POST /v1/notifications/push
    func sendTestPush(
        userId: String,
        title: String,
        subtitle: String,
        body: String
    ) async throws {
        print("📤 [NotificationRepository] Sending test push to user: \(userId)")
        print("   - title: \(title)")
        print("   - subtitle: \(subtitle)")
        print("   - body: \(body)")

        // 서버에 푸시 테스트 요청 (인증 필요 → shared 사용)
        _ = try await NetworkManager.shared.fetch(
            dto: EmptyResponse.self,
            router: NotificationRouter.sendTestPush(
                userId: userId,
                title: title,
                subtitle: subtitle,
                body: body
            )
        )

        print("✅ [NotificationRepository] Test push sent successfully")
    }

    /// FCM Token 업데이트
    /// - Parameter deviceToken: FCM Registration Token
    /// - Note: PUT /v1/users/deviceToken
    /// - Important: 사용자가 로그인 후 FCM 토큰이 변경되었을 때 호출
    func updateDeviceToken(_ deviceToken: String) async throws {
        print("📤 [NotificationRepository] Updating FCM Token: \(deviceToken.prefix(20))...")

        // 서버에 FCM 토큰 업데이트 요청 (인증 필요 → shared 사용)
        // 서버가 빈 응답(200 OK만)을 보내므로 fetchWithoutResponse 사용
        try await NetworkManager.shared.fetchWithoutResponse(
            router: NotificationRouter.updateDeviceToken(deviceToken: deviceToken)
        )

        print("✅ [NotificationRepository] FCM Token updated successfully")
    }
}

/// 응답 본문이 없는 API용 빈 DTO
struct EmptyResponse: DTO, Decodable {}
