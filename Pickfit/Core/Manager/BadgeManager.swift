//
//  BadgeManager.swift
//  Pickfit
//
//  Created by Claude on 10/19/25.
//

import UIKit

/// 읽지 않은 메시지 개수(배지)를 관리하는 매니저
/// - 채팅방별 읽지 않은 메시지 개수 추적
/// - 앱 아이콘 배지 업데이트
/// - 탭바 배지 업데이트
final class BadgeManager {

    /// 싱글톤 인스턴스
    static let shared = BadgeManager()

    /// 각 채팅방의 읽지 않은 메시지 개수
    /// - Key: roomId (채팅방 ID)
    /// - Value: 읽지 않은 메시지 개수
    private var unreadCounts: [String: Int] = [:]

    private init() {
        print("📊 [BadgeManager] Initialized")
    }

    // MARK: - Public Methods

    /// 특정 채팅방의 읽지 않은 메시지 개수 증가
    /// - Parameter roomId: 메시지를 받은 채팅방 ID
    func incrementUnreadCount(for roomId: String) {
        let currentCount = unreadCounts[roomId] ?? 0
        unreadCounts[roomId] = currentCount + 1

        print("📊 [BadgeManager] Incremented unread count for \(roomId): \(currentCount) → \(currentCount + 1)")

        // 배지 자동 업데이트
        updateAppBadge()
        notifyBadgeUpdate()
    }

    /// 특정 채팅방의 읽지 않은 메시지 개수 초기화
    /// - Parameter roomId: 초기화할 채팅방 ID
    /// - Note: 사용자가 채팅방에 진입하면 호출됨
    func clearUnreadCount(for roomId: String) {
        let previousCount = unreadCounts[roomId] ?? 0

        if previousCount > 0 {
            unreadCounts[roomId] = 0
            print("📊 [BadgeManager] Cleared unread count for \(roomId): \(previousCount) → 0")

            // 배지 자동 업데이트
            updateAppBadge()
            notifyBadgeUpdate()
        }
    }

    /// 전체 읽지 않은 메시지 개수 조회
    /// - Returns: 모든 채팅방의 읽지 않은 메시지 총합
    func getTotalUnreadCount() -> Int {
        let total = unreadCounts.values.reduce(0, +)
        print("📊 [BadgeManager] Total unread count: \(total)")
        return total
    }

    /// 특정 채팅방의 읽지 않은 메시지 개수 조회
    /// - Parameter roomId: 조회할 채팅방 ID
    /// - Returns: 해당 방의 읽지 않은 메시지 개수
    func getUnreadCount(for roomId: String) -> Int {
        return unreadCounts[roomId] ?? 0
    }

    /// 모든 채팅방의 읽지 않은 메시지 개수 초기화
    /// - Note: 로그아웃 시 호출됨
    func clearAllUnreadCounts() {
        unreadCounts.removeAll()
        print("📊 [BadgeManager] All unread counts cleared")

        // 배지 자동 업데이트
        updateAppBadge()
        notifyBadgeUpdate()
    }

    /// 앱 아이콘 배지 업데이트
    /// - Note: 홈 화면 앱 아이콘 오른쪽 위에 표시되는 빨간 숫자
    func updateAppBadge() {
        let totalCount = getTotalUnreadCount()

        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = totalCount
            print("📊 [BadgeManager] App icon badge updated: \(totalCount)")
        }
    }

    /// 탭바 배지 업데이트를 위한 알림 발송
    /// - Note: MainTabBarController가 이 알림을 받아서 탭바 배지를 업데이트함
    private func notifyBadgeUpdate() {
        NotificationCenter.default.post(
            name: .updateChatBadge,
            object: nil,
            userInfo: ["totalCount": getTotalUnreadCount()]
        )
    }

    // MARK: - Development Helper

    /// 개발/디버깅용: 현재 상태 출력
    func printStatus() {
        print("📊 [BadgeManager] ===== Current Status =====")
        print("📊 [BadgeManager] Total unread: \(getTotalUnreadCount())")
        for (roomId, count) in unreadCounts where count > 0 {
            print("📊 [BadgeManager]   - Room \(roomId): \(count) unread")
        }
        print("📊 [BadgeManager] ===========================")
    }
}
