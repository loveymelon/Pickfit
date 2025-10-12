//
//  ChatStorage.swift
//  Pickfit
//
//  Created by Claude on 10/12/25.
//

import Foundation
import CoreData

/// CoreData 채팅 메시지 저장소
/// Entity <-> ManagedObject 변환 및 CRUD 제공
final class ChatStorage {

    // MARK: - Singleton

    static let shared = ChatStorage()

    private init() {}

    // MARK: - Context

    private var context: NSManagedObjectContext {
        return CoreDataManager.shared.viewContext
    }

    // MARK: - Save Message

    /// 채팅 메시지 저장 (Entity → CoreData)
    /// - Parameter entity: ChatMessageEntity
    func saveMessage(_ entity: ChatMessageEntity) async {
        await MainActor.run {
            // 중복 체크: 같은 chatId가 이미 있으면 무시
            if fetchMessage(chatId: entity.chatId) != nil {
                print("⚠️ 중복 메시지 무시: \(entity.chatId)")
                return
            }

            let mo = ChatMessageMO(context: context)
            mo.chatId = entity.chatId
            mo.roomId = entity.roomId
            mo.content = entity.content
            mo.createdAt = entity.createdAt
            mo.updatedAt = entity.updatedAt
            mo.senderId = entity.sender.userId
            mo.senderNick = entity.sender.nickname
            mo.senderProfileImage = entity.sender.profileImageUrl
            mo.isMyMessage = entity.isMyMessage

            // files 배열 → JSON 문자열
            if !entity.files.isEmpty {
                let jsonData = try? JSONEncoder().encode(entity.files)
                mo.filesJSON = jsonData.flatMap { String(data: $0, encoding: .utf8) }
            } else {
                mo.filesJSON = nil
            }

            CoreDataManager.shared.saveContext()
            print("✅ 메시지 저장: \(entity.chatId)")
        }
    }

    /// 여러 메시지 일괄 저장
    /// - Parameter entities: [ChatMessageEntity]
    func saveMessages(_ entities: [ChatMessageEntity]) async {
        for entity in entities {
            await saveMessage(entity)
        }
    }

    // MARK: - Fetch Messages

    /// 특정 채팅방의 모든 메시지 조회
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: [ChatMessageEntity] (시간 순 정렬)
    func fetchMessages(roomId: String) -> [ChatMessageEntity] {
        let fetchRequest: NSFetchRequest<ChatMessageMO> = ChatMessageMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        do {
            let results = try context.fetch(fetchRequest)
            return results.map { toEntity($0) }
        } catch {
            print("❌ 메시지 조회 실패: \(error)")
            return []
        }
    }

    /// 특정 메시지 조회 (chatId로)
    /// - Parameter chatId: 메시지 ID
    /// - Returns: ChatMessageEntity?
    func fetchMessage(chatId: String) -> ChatMessageEntity? {
        let fetchRequest: NSFetchRequest<ChatMessageMO> = ChatMessageMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chatId == %@", chatId)
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            return results.first.map { toEntity($0) }
        } catch {
            print("❌ 메시지 조회 실패: \(error)")
            return nil
        }
    }

    /// 특정 채팅방의 마지막 메시지 ID 조회 (안읽음 판단용)
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: chatId (마지막 메시지 ID)
    func fetchLastChatId(roomId: String) -> String? {
        let fetchRequest: NSFetchRequest<ChatMessageMO> = ChatMessageMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            return results.first?.chatId
        } catch {
            print("❌ 마지막 메시지 조회 실패: \(error)")
            return nil
        }
    }

    // MARK: - Delete Messages

    /// 특정 채팅방의 모든 메시지 삭제
    /// - Parameter roomId: 채팅방 ID
    func deleteMessages(roomId: String) {
        let fetchRequest: NSFetchRequest<ChatMessageMO> = ChatMessageMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)

        do {
            let results = try context.fetch(fetchRequest)
            for mo in results {
                context.delete(mo)
            }
            CoreDataManager.shared.saveContext()
            print("✅ 채팅방 메시지 삭제: \(roomId)")
        } catch {
            print("❌ 메시지 삭제 실패: \(error)")
        }
    }

    /// 모든 메시지 삭제
    func deleteAllMessages() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ChatMessageMO.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            CoreDataManager.shared.saveContext()
            print("✅ 모든 메시지 삭제 완료")
        } catch {
            print("❌ 메시지 삭제 실패: \(error)")
        }
    }

    // MARK: - ManagedObject → Entity 변환

    /// ChatMessageMO를 ChatMessageEntity로 변환
    private func toEntity(_ mo: ChatMessageMO) -> ChatMessageEntity {
        // filesJSON → [String] 변환
        var files: [String] = []
        if let filesJSON = mo.filesJSON,
           let data = filesJSON.data(using: .utf8) {
            files = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }

        return ChatMessageEntity(
            chatId: mo.chatId ?? "",
            roomId: mo.roomId ?? "",
            content: mo.content ?? "",
            createdAt: mo.createdAt ?? "",
            updatedAt: mo.updatedAt ?? "",
            sender: ChatSenderEntity(
                userId: mo.senderId ?? "",
                nickname: mo.senderNick ?? "",
                profileImageUrl: mo.senderProfileImage
            ),
            files: files,
            isMyMessage: mo.isMyMessage
        )
    }
}
