//
//  ExNotification.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import Foundation

extension Notification.Name {
    // 기존
    static let navigateToLogin = Notification.Name("navigateToLogin")

    // 채팅 알림 관련
    /// In-App 배너를 표시하라는 신호
    /// - userInfo: ["roomId": String, "nickname": String, "message": String, "profileImage": String?]
    static let showInAppNotification = Notification.Name("showInAppNotification")

    /// 특정 채팅방을 열라는 신호 (푸시 탭 시)
    /// - userInfo: ["roomId": String]
    static let openChatRoom = Notification.Name("openChatRoom")

    /// 탭바 배지를 업데이트하라는 신호
    /// - userInfo: ["totalCount": Int]
    static let updateChatBadge = Notification.Name("updateChatBadge")
}
