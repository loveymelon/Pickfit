//
//  BadgeManager.swift
//  Pickfit
//
//  Created by 김진수 on 10/19/25.
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
        // TODO: 탭바 배지 복원 기능 (일단 주석처리)
        // DispatchQueue.main.async { [weak self] in
        //     self?.restoreFromAppIconBadge()
        // }
    }

    /// 앱 아이콘 배지에서 총 개수 복원
    /// - Note: 앱 실행 시 호출되며, 앱이 꺼져 있을 때의 배지 개수를 탭바에 반영
    // @MainActor
    // private func restoreFromAppIconBadge() {
    //     let savedBadgeCount = UIApplication.shared.applicationIconBadgeNumber
    //
    //     if savedBadgeCount > 0 {
    //         // 임시로 전체 카운트를 저장 (특정 roomId 없이)
    //         unreadCounts["__total__"] = savedBadgeCount
    //
    //         // 탭바 배지 즉시 업데이트
    //         notifyBadgeUpdate()
    //     }
    // }

    // MARK: - Public Methods

    /// 특정 채팅방의 읽지 않은 메시지 개수 설정 (초기 로드 시)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - count: 설정할 개수
    func setUnreadCount(for roomId: String, count: Int) {
        let oldCount = unreadCounts[roomId] ?? 0
        unreadCounts[roomId] = count

        // __total__도 차이만큼 조정
        let diff = count - oldCount
        let totalCount = unreadCounts["__total__"] ?? 0
        unreadCounts["__total__"] = max(0, totalCount + diff)

        // 배지 자동 업데이트
        updateAppBadge()
        notifyBadgeUpdate()
    }

    /// 특정 채팅방의 읽지 않은 메시지 개수 증가 (푸시 알림 시)
    /// - Parameter roomId: 메시지를 받은 채팅방 ID
    func incrementUnreadCount(for roomId: String) {
        // 개별 방 카운트 증가
        let currentCount = unreadCounts[roomId] ?? 0
        unreadCounts[roomId] = currentCount + 1

        // __total__ 카운트도 증가
        let totalCount = unreadCounts["__total__"] ?? 0
        unreadCounts["__total__"] = totalCount + 1

        // 배지 자동 업데이트
        updateAppBadge()
        notifyBadgeUpdate()

        print("📊 [BadgeManager] Incremented \(roomId): \(currentCount) → \(currentCount + 1)")
    }

    /// 특정 채팅방의 읽지 않은 메시지 개수 초기화
    /// - Parameter roomId: 초기화할 채팅방 ID
    /// - Note: 사용자가 채팅방에 진입하면 호출됨
    func clearUnreadCount(for roomId: String) {
        let previousCount = unreadCounts[roomId] ?? 0

        if previousCount > 0 {
            unreadCounts[roomId] = 0

            // __total__에서도 해당 방의 카운트 빼기
            let totalCount = unreadCounts["__total__"] ?? 0
            unreadCounts["__total__"] = max(0, totalCount - previousCount)

            // 배지 자동 업데이트
            updateAppBadge()
            notifyBadgeUpdate()
        }
    }

    /// 전체 읽지 않은 메시지 개수 조회
    /// - Returns: 모든 채팅방의 읽지 않은 메시지 총합
    func getTotalUnreadCount() -> Int {
        // __total__ 키에서 직접 읽기 (앱 아이콘 배지 복원 포함)
        return unreadCounts["__total__"] ?? 0
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
