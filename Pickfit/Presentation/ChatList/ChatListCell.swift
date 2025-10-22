//
//  ChatListCell.swift
//  Pickfit
//
//  Created by Claude on 10/11/25.
//

import UIKit
import SnapKit
import Then

final class ChatListCell: UITableViewCell {

    private let cardView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.05
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    private let profileImageView = ImageLoadView(cornerRadius: 28).then {
        $0.backgroundColor = .systemGray6
    }

    private let nicknameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .black
    }

    private let lastMessageLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .systemGray
        $0.numberOfLines = 1
    }

    private let timeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .systemGray2
    }

    private let unreadBadge = UIView().then {
        $0.backgroundColor = .systemRed
        $0.layer.cornerRadius = 10
        $0.isHidden = true
    }

    private let unreadLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 11, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .center
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(profileImageView)
        cardView.addSubview(nicknameLabel)
        cardView.addSubview(lastMessageLabel)
        cardView.addSubview(timeLabel)
        cardView.addSubview(unreadBadge)
        unreadBadge.addSubview(unreadLabel)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-4)
            $0.height.equalTo(80)
        }

        profileImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(56)
        }

        timeLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.equalToSuperview().offset(16)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
        }

        lastMessageLabel.snp.makeConstraints {
            $0.leading.equalTo(nicknameLabel)
            $0.top.equalTo(nicknameLabel.snp.bottom).offset(6)
            $0.trailing.equalTo(unreadBadge.snp.leading).offset(-8)
        }

        unreadBadge.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalTo(lastMessageLabel)
            $0.height.equalTo(20)
            $0.width.equalTo(20) // 최소 너비 20 (원형)
        }

        unreadLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().offset(-6)
        }
    }

    func configure(with chatRoom: ChatRoomEntity, isInitialLoad: Bool = false) {
        // Get other participant (not me)
        let currentUserId = KeychainAuthStorage.shared.readUserIdSync() ?? ""
        let otherParticipant = chatRoom.participants.first { $0.userId != currentUserId }

        // Profile image
        if let profileImageUrl = otherParticipant?.profileImage, !profileImageUrl.isEmpty {
            profileImageView.loadImage(from: profileImageUrl)
        } else {
            profileImageView.cancelLoading()
        }

        // Nickname
        nicknameLabel.text = otherParticipant?.nick ?? "알 수 없음"

        // Last message
        if let lastChat = chatRoom.lastChat {
            lastMessageLabel.text = lastChat.content
            timeLabel.text = formatDate(lastChat.createdAt)
        } else {
            lastMessageLabel.text = "메시지가 없습니다"
            timeLabel.text = formatDate(chatRoom.createdAt)
        }

        // Show unread count badge
        if isInitialLoad {
            // 처음 로드: API 호출해서 정확한 개수 계산
            calculateUnreadCountFromAPI(chatRoom: chatRoom)
        } else {
            // 이후: BadgeManager에서 가져오기 (푸시 알림으로 +1 된 값)
            showUnreadCountFromBadgeManager(chatRoom: chatRoom)
        }
    }

    /// BadgeManager에서 안읽은 개수 가져오기 (푸시 알림으로 업데이트된 값)
    /// - Parameter chatRoom: 채팅방 Entity
    private func showUnreadCountFromBadgeManager(chatRoom: ChatRoomEntity) {
        let count = BadgeManager.shared.getUnreadCount(for: chatRoom.roomId)
        print("📊 [ChatListCell] Badge from manager for \(chatRoom.roomId): \(count)")
        updateUnreadBadge(count: count)
    }

    /// 처음 로드 시: API 호출해서 안읽은 개수 계산 및 BadgeManager 초기화
    /// - Parameter chatRoom: 채팅방 Entity (API 응답)
    private func calculateUnreadCountFromAPI(chatRoom: ChatRoomEntity) {
        print("🔍 [ChatListCell] Initial load for room: \(chatRoom.roomId)")

        // 1. CoreData에서 lastReadChatId 조회
        guard let lastReadChatId = ChatRoomStorage.shared.fetchLastReadChatId(roomId: chatRoom.roomId) else {
            // 한 번도 안 읽음 = API의 lastChat이 있으면 1개
            let count = chatRoom.lastChat != nil ? 1 : 0
            print("📊 [ChatListCell] Never read, count: \(count)")
            BadgeManager.shared.setUnreadCount(for: chatRoom.roomId, count: count)
            updateUnreadBadge(count: count)
            return
        }

        // 2. API의 lastChat과 비교
        guard let apiLastChatId = chatRoom.lastChat?.chatId else {
            print("📊 [ChatListCell] No lastChat from API")
            BadgeManager.shared.setUnreadCount(for: chatRoom.roomId, count: 0)
            updateUnreadBadge(count: 0)
            return
        }

        // 3. 이미 읽음 → API 호출 안 함
        if lastReadChatId == apiLastChatId {
            print("✅ [ChatListCell] Already read")
            BadgeManager.shared.setUnreadCount(for: chatRoom.roomId, count: 0)
            updateUnreadBadge(count: 0)
            return
        }

        // 4. 안읽은 메시지 있음 → API 호출
        print("📡 [ChatListCell] Calling API for initial count...")
        Task {
            await fetchUnreadCountFromAPIAndUpdate(chatRoom: chatRoom)
        }
    }

    /// API 호출로 안읽은 메시지 개수 조회 및 BadgeManager 업데이트
    /// - Parameter chatRoom: 채팅방 Entity
    @MainActor
    private func fetchUnreadCountFromAPIAndUpdate(chatRoom: ChatRoomEntity) async {
        // ChatStorage에서 마지막 읽은 메시지 날짜 조회
        guard let lastReadDate = ChatStorage.shared.fetchLastMessageDate(roomId: chatRoom.roomId) else {
            print("⚠️ [ChatListCell] No lastReadDate found in CoreData")
            BadgeManager.shared.setUnreadCount(for: chatRoom.roomId, count: 0)
            updateUnreadBadge(count: 0)
            return
        }

        print("📡 [ChatListCell] Calling API with next: \(lastReadDate)")

        do {
            // 채팅 내역 조회 API (next 파라미터로 마지막 읽은 메시지 이후만 조회)
            let response = try await NetworkManager.shared.fetch(
                dto: ChatHistoryResponseDTO.self,
                router: ChatRouter.fetchChatHistory(
                    roomId: chatRoom.roomId,
                    next: lastReadDate
                )
            )

            // 배열 개수 = 안읽은 메시지 개수
            let unreadCount = response.data.count
            print("✅ [ChatListCell] API response: \(unreadCount) unread messages")

            // BadgeManager에 초기값 설정
            BadgeManager.shared.setUnreadCount(for: chatRoom.roomId, count: unreadCount)
            updateUnreadBadge(count: unreadCount)

        } catch {
            print("❌ [ChatListCell] Failed to fetch unread count for \(chatRoom.roomId): \(error)")
            BadgeManager.shared.setUnreadCount(for: chatRoom.roomId, count: 0)
            updateUnreadBadge(count: 0)
        }
    }

    /// 안읽은 배지 UI 업데이트
    /// - Parameter count: 안읽은 메시지 개수
    private func updateUnreadBadge(count: Int) {
        if count > 0 {
            unreadBadge.isHidden = false
            unreadLabel.text = count > 99 ? "99+" : "\(count)"
        } else {
            unreadBadge.isHidden = true
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: dateString) else { return "" }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM.dd"
            return formatter.string(from: date)
        }
    }
}
