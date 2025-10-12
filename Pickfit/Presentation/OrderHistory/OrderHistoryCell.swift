//
//  OrderHistoryCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import UIKit
import SnapKit
import Then

final class OrderHistoryCell: UITableViewCell {

    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray5.cgColor
    }

    private let storeImageView = ImageLoadView(cornerRadius: 8).then {
        $0.backgroundColor = .systemGray6
    }

    private let storeNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .black
    }

    private let orderCodeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .systemGray
    }

    private let statusBadge = UIView().then {
        $0.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        $0.layer.cornerRadius = 12
    }

    private let statusLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .semibold)
        $0.textColor = .systemBlue
    }

    private let menuNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .darkGray
    }

    private let menuCountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .systemGray
    }

    private let priceLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
    }

    private let dateLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .systemGray2
    }

    private let chevronImageView = UIImageView().then {
        $0.image = UIImage(systemName: "chevron.right")
        $0.tintColor = .systemGray3
        $0.contentMode = .scaleAspectFit
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

        contentView.addSubview(containerView)
        containerView.addSubview(storeImageView)
        containerView.addSubview(storeNameLabel)
        containerView.addSubview(orderCodeLabel)
        containerView.addSubview(statusBadge)
        statusBadge.addSubview(statusLabel)
        containerView.addSubview(menuNameLabel)
        containerView.addSubview(menuCountLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(chevronImageView)

        containerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-8)
        }

        storeImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.width.height.equalTo(60)
        }

        storeNameLabel.snp.makeConstraints {
            $0.leading.equalTo(storeImageView.snp.trailing).offset(12)
            $0.top.equalTo(storeImageView)
            $0.trailing.lessThanOrEqualTo(statusBadge.snp.leading).offset(-8)
        }

        orderCodeLabel.snp.makeConstraints {
            $0.leading.equalTo(storeNameLabel)
            $0.top.equalTo(storeNameLabel.snp.bottom).offset(4)
        }

        statusBadge.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalTo(storeNameLabel)
            $0.height.equalTo(24)
        }

        statusLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10)
            $0.trailing.equalToSuperview().offset(-10)
            $0.centerY.equalToSuperview()
        }

        menuNameLabel.snp.makeConstraints {
            $0.leading.equalTo(storeNameLabel)
            $0.top.equalTo(storeImageView.snp.bottom).offset(12)
            $0.trailing.equalToSuperview().offset(-40)
        }

        menuCountLabel.snp.makeConstraints {
            $0.leading.equalTo(menuNameLabel)
            $0.top.equalTo(menuNameLabel.snp.bottom).offset(4)
        }

        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalTo(menuNameLabel)
        }

        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(storeNameLabel)
            $0.top.equalTo(menuCountLabel.snp.bottom).offset(8)
            $0.bottom.equalToSuperview().offset(-12)
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalTo(dateLabel)
            $0.width.height.equalTo(16)
        }
    }

    func configure(with order: OrderHistoryEntity) {
        // Store info
        if let firstImageUrl = order.store.storeImageUrls.first {
            storeImageView.loadImage(from: firstImageUrl)
        }
        storeNameLabel.text = order.store.name
        orderCodeLabel.text = "주문번호 \(order.orderCode)"

        // Status
        statusLabel.text = order.currentOrderStatus.displayText
        updateStatusBadgeColor(for: order.currentOrderStatus)

        // Menu info
        if let firstMenu = order.orderMenuList.first {
            menuNameLabel.text = firstMenu.menu.name
            let totalCount = order.orderMenuList.reduce(0) { $0 + $1.quantity }
            if totalCount > 1 {
                menuCountLabel.text = "외 \(totalCount - 1)개"
            } else {
                menuCountLabel.text = ""
            }
        }

        // Price
        priceLabel.text = formatPrice(order.totalPrice) + "원"

        // Date
        dateLabel.text = formatDate(order.createdAt)
    }

    private func updateStatusBadgeColor(for status: OrderStatus) {
        switch status {
        case .pendingApproval:
            statusBadge.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
            statusLabel.textColor = .systemOrange
        case .approved:
            statusBadge.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            statusLabel.textColor = .systemBlue
        case .inProgress:
            statusBadge.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
            statusLabel.textColor = .systemPurple
        case .readyForPickup:
            statusBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
            statusLabel.textColor = .systemGreen
        case .pickedUp:
            statusBadge.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
            statusLabel.textColor = .systemGray
        case .cancelled:
            statusBadge.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
            statusLabel.textColor = .systemRed
        }
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }

    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: dateString) else { return dateString }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }
}
