//
//  ChatMessageCell.swift
//  Pickfit
//
//  Created by Claude on 10/12/25.
//

import UIKit
import SnapKit
import Then

final class ChatMessageCell: UITableViewCell {

    private let profileImageView = UIImageView().then {
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }

    private let messageBubble = UIView().then {
        $0.layer.cornerRadius = 16
        $0.layer.masksToBounds = true
    }

    private let messageLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15)
        $0.numberOfLines = 0
    }

    private let timeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 11)
        $0.textColor = .systemGray
    }

    private var isMyMessage = false

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

        contentView.addSubview(profileImageView)
        contentView.addSubview(messageBubble)
        messageBubble.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
    }

    func configure(with message: ChatMessageEntity) {
        isMyMessage = message.isMyMessage
        messageLabel.text = message.content

        // 시간 포맷
        timeLabel.text = formatTime(message.createdAt)

        // 레이아웃 업데이트
        updateLayout()
    }

    private func updateLayout() {
        // 기존 constraints 제거
        profileImageView.snp.removeConstraints()
        messageBubble.snp.removeConstraints()
        messageLabel.snp.removeConstraints()
        timeLabel.snp.removeConstraints()

        if isMyMessage {
            // 내 메시지 (오른쪽 정렬, 핑크색)
            profileImageView.isHidden = true
            messageBubble.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
            messageLabel.textColor = .white

            messageBubble.snp.makeConstraints {
                $0.top.equalToSuperview().offset(4)
                $0.trailing.equalToSuperview().offset(-16)
                $0.bottom.equalToSuperview().offset(-4)
                $0.width.lessThanOrEqualTo(250)
            }

            messageLabel.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))
            }

            timeLabel.snp.makeConstraints {
                $0.trailing.equalTo(messageBubble.snp.leading).offset(-6)
                $0.bottom.equalTo(messageBubble)
            }

        } else {
            // 상대방 메시지 (왼쪽 정렬, 회색)
            profileImageView.isHidden = false
            messageBubble.backgroundColor = .systemGray6
            messageLabel.textColor = .black

            profileImageView.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(16)
                $0.top.equalToSuperview().offset(4)
                $0.width.height.equalTo(32)
            }

            messageBubble.snp.makeConstraints {
                $0.top.equalToSuperview().offset(4)
                $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
                $0.bottom.equalToSuperview().offset(-4)
                $0.width.lessThanOrEqualTo(250)
            }

            messageLabel.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))
            }

            timeLabel.snp.makeConstraints {
                $0.leading.equalTo(messageBubble.snp.trailing).offset(6)
                $0.bottom.equalTo(messageBubble)
            }
        }
    }

    private func formatTime(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: dateString) else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timeLabel.text = nil
    }
}
