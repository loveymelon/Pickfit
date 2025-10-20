//
//  NotificationRouter.swift
//  Pickfit
//
//  Created by Claude on 10/19/25.
//

import Foundation
import Alamofire

enum NotificationRouter: Router {
    /// 푸시 알림 테스트 전송
    /// - POST /v1/notifications/push
    case sendTestPush(userId: String, title: String, subtitle: String, body: String)

    /// deviceToken 업데이트
    /// - PUT /v1/users/deviceToken
    case updateDeviceToken(deviceToken: String)
}

extension NotificationRouter {
    var method: HTTPMethod {
        switch self {
        case .sendTestPush:
            return .post
        case .updateDeviceToken:
            return .put
        }
    }

    var path: String {
        switch self {
        case .sendTestPush:
            return "/notifications/push"
        case .updateDeviceToken:
            return "/users/deviceToken"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        // 모든 경우 기본 헤더 사용
        return HTTPHeaders([
            HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey),
            HTTPHeader(name: "accept", value: "application/json")
        ])
    }

    var parameters: Parameters? {
        return nil
    }

    var body: Data? {
        switch self {
        case let .sendTestPush(userId, title, subtitle, body):
            // JSON body 생성
            let requestBody: [String: Any] = [
                "user_id": userId,
                "title": title,
                "subtitle": subtitle,
                "body": body
            ]
            return try? JSONSerialization.data(withJSONObject: requestBody)

        case let .updateDeviceToken(deviceToken):
            // JSON body 생성
            let requestBody: [String: String] = [
                "deviceToken": deviceToken
            ]
            return try? JSONSerialization.data(withJSONObject: requestBody)
        }
    }

    var encodingType: EncodingType {
        return .json
    }
}
