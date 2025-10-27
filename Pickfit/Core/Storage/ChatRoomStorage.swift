//
//  ChatRoomStorage.swift
//  Pickfit
//
//  Created by 김진수 on 10/21/25.
//

import Foundation
import CoreData

/// CoreData 채팅방 저장소
/// ChatRoom Entity CRUD 및 lastReadChatId 관리
final class ChatRoomStorage {

    // MARK: - Singleton

    static let shared = ChatRoomStorage()

    private init() {}

    // MARK: - Context

    private var context: NSManagedObjectContext {
        return CoreDataManager.shared.viewContext
    }

    // MARK: - Fetch or Create

    /// 채팅방 조회 또는 생성 (Upsert 패턴)
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: ChatRoom ManagedObject
    func fetchOrCreateChatRoom(roomId: String) -> ChatRoom {
        let fetchRequest: NSFetchRequest<ChatRoom> = ChatRoom.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
        fetchRequest.fetchLimit = 1

        do {
            if let existing = try context.fetch(fetchRequest).first {
                return existing
            }
        } catch {
            print("❌ [ChatRoomStorage] Fetch error: \(error)")
        }

        // 새 ChatRoom 생성
        let chatRoom = ChatRoom(context: context)
        chatRoom.roomId = roomId
        chatRoom.updatedAt = Date().iso8601String
        print("✅ [ChatRoomStorage] Created new ChatRoom: \(roomId)")

        return chatRoom
    }

    /// 채팅방 조회
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: ChatRoom ManagedObject (없으면 nil)
    func fetchChatRoom(roomId: String) -> ChatRoom? {
        let fetchRequest: NSFetchRequest<ChatRoom> = ChatRoom.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
        fetchRequest.fetchLimit = 1

        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("❌ [ChatRoomStorage] Fetch error: \(error)")
            return nil
        }
    }

    // MARK: - Update Last Read Chat ID

    /// 마지막으로 읽은 메시지 ID 업데이트
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - lastReadChatId: 마지막으로 읽은 메시지 ID
    /// - Note: 채팅방 나갈 때 호출하여 읽음 상태 저장
    func updateLastReadChatId(roomId: String, lastReadChatId: String) {
        let chatRoom = fetchOrCreateChatRoom(roomId: roomId)
        chatRoom.lastReadChatId = lastReadChatId
        chatRoom.updatedAt = Date().iso8601String

        CoreDataManager.shared.saveContext()
        print("📝 [ChatRoomStorage] Updated lastReadChatId: \(lastReadChatId) for room: \(roomId)")
    }

    /// 마지막으로 읽은 메시지 ID 조회
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: lastReadChatId (없으면 nil)
    func fetchLastReadChatId(roomId: String) -> String? {
        guard let chatRoom = fetchChatRoom(roomId: roomId) else {
            return nil
        }
        return chatRoom.lastReadChatId
    }

    // MARK: - Fetch All

    /// 모든 채팅방의 lastReadChatId 조회
    /// - Returns: [roomId: lastReadChatId] Dictionary
    func fetchAllLastReadInfo() -> [String: String] {
        let fetchRequest: NSFetchRequest<ChatRoom> = ChatRoom.fetchRequest()

        do {
            let chatRooms = try context.fetch(fetchRequest)
            var result: [String: String] = [:]

            for chatRoom in chatRooms {
                if let roomId = chatRoom.roomId,
                   let lastReadChatId = chatRoom.lastReadChatId {
                    result[roomId] = lastReadChatId
                }
            }

            print("📊 [ChatRoomStorage] Fetched lastReadInfo for \(result.count) rooms")
            return result
        } catch {
            print("❌ [ChatRoomStorage] Fetch all error: \(error)")
            return [:]
        }
    }

    // MARK: - Delete

    /// 특정 채팅방 삭제
    /// - Parameter roomId: 채팅방 ID
    /// - Warning: Cascade Delete로 해당 방의 모든 메시지도 삭제됨
    func deleteChatRoom(roomId: String) {
        guard let chatRoom = fetchChatRoom(roomId: roomId) else {
            print("⚠️ [ChatRoomStorage] ChatRoom not found: \(roomId)")
            return
        }

        context.delete(chatRoom)
        CoreDataManager.shared.saveContext()
        print("🗑️ [ChatRoomStorage] Deleted ChatRoom: \(roomId)")
    }

    /// 모든 채팅방 삭제
    /// - Warning: Cascade Delete로 모든 메시지도 삭제됨
    func deleteAllChatRooms() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ChatRoom.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            CoreDataManager.shared.saveContext()
            print("🗑️ [ChatRoomStorage] Deleted all ChatRooms")
        } catch {
            print("❌ [ChatRoomStorage] Delete all error: \(error)")
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
