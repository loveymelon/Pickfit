//
//  RealmChatStorage.swift
//  Pickfit
//
//  Created by 김진수 on 11/10/24.
//

import Foundation
import RealmSwift

/// Realm 채팅 메시지 저장소 (Actor 기반 thread-safe)
/// Entity <-> DTO 변환 및 CRUD 제공
final actor RealmChatStorage {

    // MARK: - Singleton

    static let shared = RealmChatStorage()

    private init() {}

    // MARK: - Save Message

    /// 채팅 메시지 저장 또는 업데이트 (Upsert 패턴)
    /// - Parameter entity: ChatMessageEntity
    /// - Note: chatId가 이미 존재하면 업데이트, 없으면 새로 생성
    func saveMessage(_ entity: ChatMessageEntity) async throws {
        do {
            let realm = try await RealmManager.shared.getRealm()

            try await realm.asyncWrite {
                // Upsert: update: .modified로 기존 데이터 업데이트 또는 생성
                realm.create(
                    ChatMessageDTO.self,
                    value: ChatMessageDTO(entity: entity),
                    update: .modified
                )

                // ChatRoom과의 관계 설정
                let chatRoom = self.fetchOrCreateChatRoomSync(roomId: entity.roomId, realm: realm)
                if let message = realm.object(ofType: ChatMessageDTO.self, forPrimaryKey: entity.chatId) {
                    chatRoom.messages.append(message)
                }

#if DEBUG
                print("[RealmChatStorage] 메시지 저장 완료: \(entity.chatId)")
#endif
            }
        } catch {
            print("[RealmChatStorage] 메시지 저장 실패: \(error)")
            throw RealmError.createFailed
        }
    }

    /// 여러 메시지 일괄 저장
    /// - Parameter entities: [ChatMessageEntity]
    func saveMessages(_ entities: [ChatMessageEntity]) async {
        for entity in entities {
            try? await saveMessage(entity)
        }
    }

    // MARK: - Fetch Messages

    /// 특정 채팅방의 모든 메시지 조회
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: [ChatMessageEntity] (시간 순 정렬)
    func fetchMessages(roomId: String) async -> [ChatMessageEntity] {
        do {
            let realm = try await RealmManager.shared.getRealm()

            // ChatRoom을 먼저 찾고, 관계를 통해 메시지 조회
            guard let chatRoom = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) else {
                return []
            }

            // createdAt으로 정렬
            let sorted = chatRoom.messages.sorted(byKeyPath: "createdAt", ascending: true)
            return sorted.map { $0.toDomain() }

        } catch {
            print("[RealmChatStorage] 메시지 조회 실패: \(error)")
            return []
        }
    }

    /// 특정 채팅방의 최근 N개 메시지 조회 (Pagination - 초기 로드용)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - limit: 조회할 메시지 개수 (기본 30개)
    /// - Returns: [ChatMessageEntity] (시간 순 정렬, 최근 limit개)
    func fetchRecentMessages(roomId: String, limit: Int = 30) async -> [ChatMessageEntity] {
        do {
            let realm = try await RealmManager.shared.getRealm()

            guard let chatRoom = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) else {
                return []
            }

            // 최신순으로 정렬 후 limit개만
            let sorted = chatRoom.messages.sorted(byKeyPath: "createdAt", ascending: false)
            let limited = Array(sorted.prefix(limit))

            // 다시 오름차순으로 변환
            return limited.reversed().map { $0.toDomain() }

        } catch {
            print("[RealmChatStorage] 최근 메시지 조회 실패: \(error)")
            return []
        }
    }

    /// 특정 날짜 이전의 N개 메시지 조회 (Pagination - 이전 페이지용)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - beforeDate: 기준 날짜 (이 날짜보다 이전 메시지 조회)
    ///   - limit: 조회할 메시지 개수 (기본 30개)
    /// - Returns: [ChatMessageEntity] (시간 순 정렬)
    func fetchMessagesBefore(roomId: String, beforeDate: String, limit: Int = 30) async -> [ChatMessageEntity] {
        do {
            let realm = try await RealmManager.shared.getRealm()

            guard let chatRoom = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) else {
                return []
            }

            // beforeDate 이전 것만 필터링
            let filtered = chatRoom.messages.filter("createdAt < %@", beforeDate)
            let sorted = filtered.sorted(byKeyPath: "createdAt", ascending: false)
            let limited = Array(sorted.prefix(limit))

            return limited.reversed().map { $0.toDomain() }

        } catch {
            print("[RealmChatStorage] 이전 메시지 조회 실패: \(error)")
            return []
        }
    }

    /// 특정 메시지 조회 (chatId로)
    /// - Parameter chatId: 메시지 ID
    /// - Returns: ChatMessageEntity?
    func fetchMessage(chatId: String) async -> ChatMessageEntity? {
        do {
            let realm = try await RealmManager.shared.getRealm()

            guard let message = realm.object(ofType: ChatMessageDTO.self, forPrimaryKey: chatId) else {
                return nil
            }

            return message.toDomain()

        } catch {
            print("[RealmChatStorage] 메시지 조회 실패: \(error)")
            return nil
        }
    }

    /// 특정 채팅방의 마지막 메시지 ID 조회 (안읽음 판단용)
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: chatId (마지막 메시지 ID)
    func fetchLastChatId(roomId: String) async -> String? {
        do {
            let realm = try await RealmManager.shared.getRealm()

            guard let chatRoom = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) else {
                return nil
            }

            // 가장 최신 메시지 찾기
            let lastMessage = chatRoom.messages.sorted(byKeyPath: "createdAt", ascending: false).first
            return lastMessage?.chatId

        } catch {
            print("[RealmChatStorage] 마지막 메시지 ID 조회 실패: \(error)")
            return nil
        }
    }

    /// 특정 채팅방의 마지막 메시지 날짜 조회 (API next 파라미터용)
    /// - Parameter roomId: 채팅방 ID
    /// - Returns: createdAt (마지막 메시지 날짜)
    func fetchLastMessageDate(roomId: String) async -> String? {
        do {
            let realm = try await RealmManager.shared.getRealm()

            guard let chatRoom = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) else {
                return nil
            }

            // 가장 최신 메시지의 날짜 찾기
            let lastMessage = chatRoom.messages.sorted(byKeyPath: "createdAt", ascending: false).first
            return lastMessage?.createdAt

        } catch {
            print("[RealmChatStorage] 마지막 메시지 날짜 조회 실패: \(error)")
            return nil
        }
    }

    // MARK: - Unread Count

    /// lastReadChatId 이후의 안읽은 메시지 개수 계산
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - afterChatId: 마지막으로 읽은 메시지 ID
    /// - Returns: 안읽은 메시지 개수
    func countMessagesAfter(roomId: String, afterChatId: String) async -> Int {
        // 1. lastReadChatId의 createdAt 조회
        guard let lastReadMessage = await fetchMessage(chatId: afterChatId) else {
            print("⚠️ [RealmChatStorage] lastReadChatId not found: \(afterChatId)")
            return 0
        }

        let lastReadDate = lastReadMessage.createdAt

        // 2. ChatRoom의 messages에서 lastReadDate 이후 메시지 개수 계산
        do {
            let realm = try await RealmManager.shared.getRealm()

            guard let chatRoom = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) else {
                return 0
            }

            let unreadMessages = chatRoom.messages.filter("createdAt > %@", lastReadDate)
            let count = unreadMessages.count

#if DEBUG
            print("📊 [RealmChatStorage] Unread count for \(roomId): \(count)")
#endif
            return count

        } catch {
            print("[RealmChatStorage] 안읽은 메시지 카운트 실패: \(error)")
            return 0
        }
    }

    // MARK: - Delete Messages

    /// 특정 채팅방의 모든 메시지 삭제
    /// - Parameter roomId: 채팅방 ID
    func deleteMessages(roomId: String) async {
        // ChatRoom 삭제 시 관계된 메시지도 함께 삭제
        await RealmChatRoomStorage.shared.deleteChatRoom(roomId: roomId)
        print("[RealmChatStorage] 채팅방 메시지 삭제: \(roomId)")
    }

    /// 모든 메시지 삭제
    func deleteAllMessages() async {
        await RealmChatRoomStorage.shared.deleteAllChatRooms()
        print("[RealmChatStorage] 모든 메시지 삭제 완료")
    }

    // MARK: - Helper (Sync)

    /// ChatRoom 조회 또는 생성 (Sync - asyncWrite 내부에서 사용)
    private func fetchOrCreateChatRoomSync(roomId: String, realm: Realm) -> ChatRoomDTO {
        if let existing = realm.object(ofType: ChatRoomDTO.self, forPrimaryKey: roomId) {
            return existing
        }

        let chatRoom = ChatRoomDTO(roomId: roomId)
        realm.add(chatRoom, update: .modified)
        return chatRoom
    }
}
