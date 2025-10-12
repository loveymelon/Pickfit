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
        $0.text = "NEW"
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
        }

        unreadLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(8)
            $0.trailing.equalToSuperview().offset(-8)
        }
    }

    func configure(with chatRoom: ChatRoomEntity) {
        // Get other participant (not me)
        let currentUserId = KeychainAuthStorage.shared.readUserIdSync() ?? ""
        let otherParticipant = chatRoom.participants.first { $0.userId != currentUserId }

        // Profile image
        if let profileImageUrl = otherParticipant?.profileImage, !profileImageUrl.isEmpty {
            profileImageView.loadImage(from: profileImageUrl)
        } else {
            // ImageLoadView doesn't support direct image setting,
            // so we load a default image or leave it empty
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

        // Show "NEW" badge if unread
        unreadBadge.isHidden = !chatRoom.isUnread
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
