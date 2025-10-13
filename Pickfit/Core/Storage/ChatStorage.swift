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

    /// 채팅 메시지 저장 또는 업데이트 (Upsert 패턴)
    /// - Parameter entity: ChatMessageEntity
    /// - Note: chatId가 이미 존재하면 업데이트, 없으면 새로 생성
    ///         CloudKit 동기화 시 중복 데이터 방지를 위한 안전장치
    func saveMessage(_ entity: ChatMessageEntity) async {
        await MainActor.run {
            // chatId로 기존 메시지 조회
            let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "chatId == %@", entity.chatId)
            fetchRequest.fetchLimit = 1

            let message: Message
            do {
                let results = try context.fetch(fetchRequest)
                if let existing = results.first {
                    // 기존 메시지가 있으면 업데이트 (CloudKit 동기화로 인한 중복 방지)
                    message = existing
                    print("[ChatStorage] 기존 메시지 업데이트: \(entity.chatId)")
                } else {
                    // 새 메시지 생성
                    message = Message(context: context)
                    print("[ChatStorage] 새 메시지 생성: \(entity.chatId)")
                }
            } catch {
                print("[ChatStorage] Fetch 에러: \(error), 새 메시지로 생성")
                message = Message(context: context)
            }

            // 메시지 속성 설정 (업데이트 또는 생성 모두 동일)
            message.chatId = entity.chatId
            message.roomId = entity.roomId
            message.content = entity.content
            message.createdAt = entity.createdAt
            message.updatedAt = entity.updatedAt
            message.senderId = entity.sender.userId
            message.senderNick = entity.sender.nickname
            message.senderProfileImage = entity.sender.profileImageUrl
            message.isMyMessage = entity.isMyMessage

            // files 배열 → JSON 문자열
            if !entity.files.isEmpty {
                let jsonData = try? JSONEncoder().encode(entity.files)
                message.filesJSON = jsonData.flatMap { String(data: $0, encoding: .utf8) }
            } else {
                message.filesJSON = nil
            }

            CoreDataManager.shared.saveContext()
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
    /// - Note: roomId에 index가 설정되어 있어 빠른 조회 가능
    func fetchMessages(roomId: String) -> [ChatMessageEntity] {
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        do {
            let results = try context.fetch(fetchRequest)
            return results.map { toEntity($0) }
        } catch {
            print("[ChatStorage] 메시지 조회 실패: \(error)")
            return []
        }
    }

    /// 특정 채팅방의 최근 N개 메시지 조회 (Pagination - 초기 로드용)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - limit: 조회할 메시지 개수 (기본 30개)
    /// - Returns: [ChatMessageEntity] (시간 순 정렬, 최근 limit개)
    /// - Note: 역방향 pagination을 위해 최신 메시지부터 limit개만 조회
    func fetchRecentMessages(roomId: String, limit: Int = 30) -> [ChatMessageEntity] {
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]  // 최신순
        fetchRequest.fetchLimit = limit

        do {
            let results = try context.fetch(fetchRequest)
            // 다시 오래된 순으로 정렬하여 반환
            return results.reversed().map { toEntity($0) }
        } catch {
            print("[ChatStorage] 최근 메시지 조회 실패: \(error)")
            return []
        }
    }

    /// 특정 날짜 이전의 N개 메시지 조회 (Pagination - 이전 페이지용)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - beforeDate: 기준 날짜 (이 날짜보다 이전 메시지 조회)
    ///   - limit: 조회할 메시지 개수 (기본 30개)
    /// - Returns: [ChatMessageEntity] (시간 순 정렬)
    /// - Note: 역방향 pagination용, insertRows로 배열 앞에 추가됨
    func fetchMessagesBefore(roomId: String, beforeDate: String, limit: Int = 30) -> [ChatMessageEntity] {
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "roomId == %@ AND createdAt < %@",
            roomId,
            beforeDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]  // 최신순
        fetchRequest.fetchLimit = limit

        do {
            let results = try context.fetch(fetchRequest)
            // 다시 오래된 순으로 정렬하여 반환
            return results.reversed().map { toEntity($0) }
        } catch {
            print("[ChatStorage] 이전 메시지 조회 실패: \(error)")
            return []
        }
    }

    /// 특정 메시지 조회 (chatId로)
    /// - Parameter chatId: 메시지 ID
    /// - Returns: ChatMessageEntity?
    func fetchMessage(chatId: String) -> ChatMessageEntity? {
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chatId == %@", chatId)
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            return results.first.map { toEntity($0) }
        } catch {
            print("[ChatStorage] 메시지 조회 실패: \(error)")
            return nil
        }
    }

    /// 특정 채팅방의 마지막 메시지 ID 조회 (안읽음 판단용)
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: chatId (마지막 메시지 ID)
    func fetchLastChatId(roomId: String) -> String? {
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            return results.first?.chatId
        } catch {
            print("[ChatStorage] 마지막 메시지 조회 실패: \(error)")
            return nil
        }
    }

    /// 특정 채팅방의 마지막 메시지 날짜 조회 (API next 파라미터용)
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: createdAt (마지막 메시지 날짜)
    /// - Note: API 호출 시 next 파라미터로 전달하여 해당 날짜 이후의 메시지만 조회
    func fetchLastMessageDate(roomId: String) -> String? {
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            return results.first?.createdAt
        } catch {
            print("[ChatStorage] 마지막 메시지 날짜 조회 실패: \(error)")
            return nil
        }
    }

    // MARK: - Delete Messages

    /// 특정 채팅방의 모든 메시지 삭제
    /// - Parameter roomId: 채팅방 ID
    /// - Warning: CoreData에서 삭제하면 CloudKit에도 삭제가 전파됨 (모든 기기에서 삭제)
    func deleteMessages(roomId: String) {
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "roomId == %@", roomId)

        do {
            let results = try context.fetch(fetchRequest)
            for mo in results {
                context.delete(mo)
            }
            CoreDataManager.shared.saveContext()
            print("[ChatStorage] 채팅방 메시지 삭제: \(roomId)")
        } catch {
            print("[ChatStorage] 메시지 삭제 실패: \(error)")
        }
    }

    /// 모든 메시지 삭제
    /// - Warning: CoreData에서 삭제하면 CloudKit에도 삭제가 전파됨 (모든 기기에서 삭제)
    func deleteAllMessages() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Message.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            CoreDataManager.shared.saveContext()
            print("[ChatStorage] 모든 메시지 삭제 완료")
        } catch {
            print("[ChatStorage] 메시지 삭제 실패: \(error)")
        }
    }

    // MARK: - ManagedObject → Entity 변환

    /// Message를 ChatMessageEntity로 변환
    private func toEntity(_ mo: Message) -> ChatMessageEntity {
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
