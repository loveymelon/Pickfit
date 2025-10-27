//
//  ChatStorage.swift
//  Pickfit
//
//  Created by 김진수 on 10/12/25.
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

            // ChatRoom과의 Relationship 설정
            let chatRoom = ChatRoomStorage.shared.fetchOrCreateChatRoom(roomId: entity.roomId)
            message.room = chatRoom

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
    /// - Note: Relationship을 통한 빠른 조회
    func fetchMessages(roomId: String) -> [ChatMessageEntity] {
        // ChatRoom을 먼저 찾고, Relationship을 통해 메시지 조회
        guard let chatRoom = ChatRoomStorage.shared.fetchChatRoom(roomId: roomId) else {
            return []
        }

        // Relationship의 messages를 createdAt으로 정렬
        let messages = (chatRoom.messages?.allObjects as? [Message]) ?? []
        let sorted = messages.sorted { ($0.createdAt ?? "") < ($1.createdAt ?? "") }

        return sorted.map { toEntity($0) }
    }

    /// 특정 채팅방의 최근 N개 메시지 조회 (Pagination - 초기 로드용)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - limit: 조회할 메시지 개수 (기본 30개)
    /// - Returns: [ChatMessageEntity] (시간 순 정렬, 최근 limit개)
    /// - Note: 역방향 pagination을 위해 최신 메시지부터 limit개만 조회
    func fetchRecentMessages(roomId: String, limit: Int = 30) -> [ChatMessageEntity] {
        guard let chatRoom = ChatRoomStorage.shared.fetchChatRoom(roomId: roomId) else {
            return []
        }

        // Relationship의 messages를 최신순으로 정렬 후 limit개만
        let messages = (chatRoom.messages?.allObjects as? [Message]) ?? []
        let sorted = messages.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        let limited = Array(sorted.prefix(limit))

        return limited.reversed().map { toEntity($0) }
    }

    /// 특정 날짜 이전의 N개 메시지 조회 (Pagination - 이전 페이지용)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - beforeDate: 기준 날짜 (이 날짜보다 이전 메시지 조회)
    ///   - limit: 조회할 메시지 개수 (기본 30개)
    /// - Returns: [ChatMessageEntity] (시간 순 정렬)
    /// - Note: 역방향 pagination용, insertRows로 배열 앞에 추가됨
    func fetchMessagesBefore(roomId: String, beforeDate: String, limit: Int = 30) -> [ChatMessageEntity] {
        guard let chatRoom = ChatRoomStorage.shared.fetchChatRoom(roomId: roomId) else {
            return []
        }

        // Relationship의 messages에서 beforeDate 이전 것만 필터링
        let messages = (chatRoom.messages?.allObjects as? [Message]) ?? []
        let filtered = messages.filter { ($0.createdAt ?? "") < beforeDate }
        let sorted = filtered.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        let limited = Array(sorted.prefix(limit))

        return limited.reversed().map { toEntity($0) }
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
        guard let chatRoom = ChatRoomStorage.shared.fetchChatRoom(roomId: roomId) else {
            return nil
        }

        // Relationship의 messages에서 가장 최신 메시지 찾기
        let messages = (chatRoom.messages?.allObjects as? [Message]) ?? []
        let sorted = messages.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }

        return sorted.first?.chatId
    }

    /// 특정 채팅방의 마지막 메시지 날짜 조회 (API next 파라미터용)
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: createdAt (마지막 메시지 날짜)
    /// - Note: API 호출 시 next 파라미터로 전달하여 해당 날짜 이후의 메시지만 조회
    func fetchLastMessageDate(roomId: String) -> String? {
        guard let chatRoom = ChatRoomStorage.shared.fetchChatRoom(roomId: roomId) else {
            return nil
        }

        // Relationship의 messages에서 가장 최신 메시지의 날짜 찾기
        let messages = (chatRoom.messages?.allObjects as? [Message]) ?? []
        let sorted = messages.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }

        return sorted.first?.createdAt
    }

    // MARK: - Unread Count

    /// lastReadChatId 이후의 안읽은 메시지 개수 계산
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - afterChatId: 마지막으로 읽은 메시지 ID
    /// - Returns: 안읽은 메시지 개수
    func countMessagesAfter(roomId: String, afterChatId: String) -> Int {
        // 1. lastReadChatId의 createdAt 조회
        guard let lastReadMessage = fetchMessage(chatId: afterChatId) else {
            print("⚠️ [ChatStorage] lastReadChatId not found: \(afterChatId)")
            return 0
        }

        let lastReadDate = lastReadMessage.createdAt

        // 2. ChatRoom의 messages에서 lastReadDate 이후 메시지 개수 계산
        guard let chatRoom = ChatRoomStorage.shared.fetchChatRoom(roomId: roomId) else {
            return 0
        }

        let messages = (chatRoom.messages?.allObjects as? [Message]) ?? []
        let unreadMessages = messages.filter { ($0.createdAt ?? "") > lastReadDate }
        let count = unreadMessages.count

        print("📊 [ChatStorage] Unread count for \(roomId): \(count)")
        return count
    }

    // MARK: - Delete Messages

    /// 특정 채팅방의 모든 메시지 삭제
    /// - Parameter roomId: 채팅방 ID
    /// - Warning: CoreData에서 삭제하면 CloudKit에도 삭제가 전파됨 (모든 기기에서 삭제)
    /// - Note: ChatRoom을 삭제하면 Cascade Delete로 메시지도 자동 삭제됨
    func deleteMessages(roomId: String) {
        // ChatRoom 삭제 시 Cascade Delete로 메시지도 자동 삭제됨
        ChatRoomStorage.shared.deleteChatRoom(roomId: roomId)
        print("[ChatStorage] 채팅방 메시지 삭제 (Cascade): \(roomId)")
    }

    /// 모든 메시지 삭제
    /// - Warning: CoreData에서 삭제하면 CloudKit에도 삭제가 전파됨 (모든 기기에서 삭제)
    /// - Note: 모든 ChatRoom을 삭제하면 Cascade Delete로 메시지도 자동 삭제됨
    func deleteAllMessages() {
        // 모든 ChatRoom 삭제 → Cascade Delete로 메시지도 자동 삭제
        ChatRoomStorage.shared.deleteAllChatRooms()
        print("[ChatStorage] 모든 메시지 삭제 완료 (Cascade)")
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

        // Relationship을 통해 roomId 가져오기
        let roomId = mo.room?.roomId ?? ""

        return ChatMessageEntity(
            chatId: mo.chatId ?? "",
            roomId: roomId,
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
