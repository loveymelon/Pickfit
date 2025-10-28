//
//  ChatStateManager.swift
//  Pickfit
//
//  Created by 김진수 on 10/19/25.
//

import UIKit

/// 채팅 알림을 관리하기 위한 상태 매니저
/// - 현재 활성화된 채팅방을 추적하여 같은 방에서는 알림을 표시하지 않음
/// - Singleton 패턴으로 앱 전체에서 하나의 인스턴스만 사용
final class ChatStateManager {

    /// 싱글톤 인스턴스
    static let shared = ChatStateManager()

    /// 현재 사용자가 보고 있는 채팅방 ID
    /// - nil이면 채팅방을 보고 있지 않은 상태
    private(set) var activeRoomId: String?

    private init() {
        print("📊 [ChatStateManager] Initialized")
    }

    // MARK: - Public Methods

    /// 사용자가 특정 채팅방에 진입했을 때 호출
    /// - Parameter roomId: 진입한 채팅방의 ID
    func setActiveRoom(_ roomId: String) {
        print("📊 [ChatStateManager] Active room set: \(roomId)")
        activeRoomId = roomId
    }

    /// 사용자가 채팅방을 나갔을 때 호출
    func clearActiveRoom() {
        print("📊 [ChatStateManager] Active room cleared (was: \(activeRoomId ?? "none"))")
        activeRoomId = nil
    }

    /// 특정 채팅방이 현재 활성화되어 있는지 확인
    /// - Parameter roomId: 확인할 채팅방 ID
    /// - Returns: 해당 방이 현재 보고 있는 방이면 true
    func isRoomActive(_ roomId: String) -> Bool {
        let isActive = activeRoomId == roomId
        print("📊 [ChatStateManager] Is room \(roomId) active? \(isActive)")
        return isActive
    }

    /// 알림을 표시해야 하는지 판단하는 핵심 로직
    /// - Parameters:
    ///   - roomId: 메시지를 받은 채팅방 ID
    ///   - isMyMessage: 내가 보낸 메시지인지 여부
    /// - Returns: true면 알림 표시, false면 알림 안 함
    func shouldShowNotification(for roomId: String, isMyMessage: Bool) -> Bool {
        // 1. 내가 보낸 메시지는 알림 안 함
        if isMyMessage {
            print("🔕 [ChatStateManager] Notification blocked: My own message")
            return false
        }

        // 2. 현재 보고 있는 채팅방의 메시지는 알림 안 함
        if isRoomActive(roomId) {
            print("🔕 [ChatStateManager] Notification blocked: Room is active")
            return false
        }

        // 3. 그 외의 경우는 알림 표시
        print("🔔 [ChatStateManager] Notification allowed for room: \(roomId)")
        return true
    }
}
