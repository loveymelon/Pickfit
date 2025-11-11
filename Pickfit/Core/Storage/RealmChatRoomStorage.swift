//
//  RealmChatRoomStorage.swift
//  Pickfit
//
//  Created by 김진수 on 11/10/24.
//

import Foundation
import RealmSwift

/// Realm 채팅방 저장소 (Actor 기반 thread-safe)
/// ChatRoom Entity CRUD 및 lastReadChatId 관리
final actor RealmChatRoomStorage {

    // MARK: - Singleton

    static let shared = RealmChatRoomStorage()

    private init() {}

    // MARK: - Fetch or Create

    /// 채팅방 조회 또는 생성 (Upsert 패턴)
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: ChatRoomDTO
    func fetchOrCreateChatRoom(roomId: String) async throws -> ChatRoomDTO {
        let realm = try await RealmManager.shared.getRealm()

        if let existing = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) {
            return existing
        }

        // 새 ChatRoom 생성
        let chatRoom = ChatRoomDTO(roomId: roomId)

        try await realm.asyncWrite {
            realm.add(chatRoom, update: .modified)
        }

        print("✅ [RealmChatRoomStorage] Created new ChatRoom: \(roomId)")
        return chatRoom
    }

    /// 채팅방 조회
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: ChatRoomDTO (없으면 nil)
    func fetchChatRoom(roomId: String) async -> ChatRoomDTO? {
        do {
            let realm = try await RealmManager.shared.getRealm()
            return realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId)
        } catch {
            print("❌ [RealmChatRoomStorage] Fetch error: \(error)")
            return nil
        }
    }

    // MARK: - Update Last Read Chat ID

    /// 마지막으로 읽은 메시지 ID 업데이트
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - lastReadChatId: 마지막으로 읽은 메시지 ID
    /// - Note: 채팅방 나갈 때 호출하여 읽음 상태 저장
    func updateLastReadChatId(roomId: String, lastReadChatId: String) async {
        do {
            let realm = try await RealmManager.shared.getRealm()

            guard let chatRoom = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) else {
                print("⚠️ [RealmChatRoomStorage] ChatRoom not found: \(roomId)")
                return
            }

            try await realm.asyncWrite {
                chatRoom.lastReadChatId = lastReadChatId
                chatRoom.updatedAt = Date().iso8601String
            }

            print("📝 [RealmChatRoomStorage] Updated lastReadChatId: \(lastReadChatId) for room: \(roomId)")

        } catch {
            print("❌ [RealmChatRoomStorage] Update lastReadChatId error: \(error)")
        }
    }

    /// 마지막으로 읽은 메시지 ID 조회
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: lastReadChatId (없으면 nil)
    func fetchLastReadChatId(roomId: String) async -> String? {
        guard let chatRoom = await fetchChatRoom(roomId: roomId) else {
            return nil
        }
        return chatRoom.lastReadChatId
    }

    // MARK: - Fetch All

    /// 모든 채팅방의 lastReadChatId 조회
    /// - Returns: [roomId: lastReadChatId] Dictionary
    func fetchAllLastReadInfo() async -> [String: String] {
        do {
            let realm = try await RealmManager.shared.getRealm()

            let chatRooms = realm.objects(ChatRoomDTO.self)
            var result: [String: String] = [:]

            for chatRoom in chatRooms {
                if let lastReadChatId = chatRoom.lastReadChatId {
                    result[chatRoom.roomId] = lastReadChatId
                }
            }

            print("📊 [RealmChatRoomStorage] Fetched lastReadInfo for \(result.count) rooms")
            return result

        } catch {
            print("❌ [RealmChatRoomStorage] Fetch all error: \(error)")
            return [:]
        }
    }

    // MARK: - Delete

    /// 특정 채팅방 삭제
    /// - Parameter roomId: 채팅방 ID
    /// - Note: ChatRoom 삭제 시 관계된 메시지도 함께 정리
    func deleteChatRoom(roomId: String) async {
        do {
            let realm = try await RealmManager.shared.getRealm()

            guard let chatRoom = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) else {
                print("⚠️ [RealmChatRoomStorage] ChatRoom not found: \(roomId)")
                return
            }

            try await realm.asyncWrite {
                // 관계된 메시지들도 함께 삭제
                realm.delete(chatRoom.messages)
                realm.delete(chatRoom)
            }

            print("🗑️ [RealmChatRoomStorage] Deleted ChatRoom: \(roomId)")

        } catch {
            print("❌ [RealmChatRoomStorage] Delete error: \(error)")
        }
    }

    /// 모든 채팅방 삭제
    func deleteAllChatRooms() async {
        do {
            let realm = try await RealmManager.shared.getRealm()

            let chatRooms = realm.objects(ChatRoomDTO.self)

            try await realm.asyncWrite {
                // 모든 메시지와 채팅방 삭제
                let allMessages = realm.objects(ChatMessageDTO.self)
                realm.delete(allMessages)
                realm.delete(chatRooms)
            }

            print("🗑️ [RealmChatRoomStorage] Deleted all ChatRooms")

        } catch {
            print("❌ [RealmChatRoomStorage] Delete all error: \(error)")
        }
    }
}

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
