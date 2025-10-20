//
//  OrderHistoryRowCell.swift
//  Pickfit
//
//  Created by Claude on 2025-10-19.
//

import UIKit
import SnapKit
import Then

final class OrderHistoryRowCell: UITableViewCell {

    // MARK: - UI Components

    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
    }

    private let menuImageView = ImageLoadView(cornerRadius: 8).then {
        $0.backgroundColor = .systemGray6
    }

    private let storeNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .semibold)
        $0.textColor = .black
    }

    private let dateLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .systemGray2
    }

    private let menuNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .darkGray
    }

    private let priceLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .bold)
        $0.textColor = .black
        $0.textAlignment = .right
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
        containerView.addSubview(menuImageView)
        containerView.addSubview(storeNameLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(menuNameLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(chevronImageView)

        containerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-4)
        }

        menuImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(50)
        }

        storeNameLabel.snp.makeConstraints {
            $0.leading.equalTo(menuImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.trailing.lessThanOrEqualTo(priceLabel.snp.leading).offset(-8)
        }

        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(storeNameLabel)
            $0.top.equalTo(storeNameLabel.snp.bottom).offset(2)
        }

        menuNameLabel.snp.makeConstraints {
            $0.leading.equalTo(storeNameLabel)
            $0.top.equalTo(dateLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().offset(-12)
            $0.trailing.lessThanOrEqualTo(priceLabel.snp.leading).offset(-8)
        }

        priceLabel.snp.makeConstraints {
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(14)
        }
    }

    func configure(with order: OrderHistoryEntity) {
        // Menu image (첫 번째 메뉴 이미지)
        if let firstMenu = order.orderMenuList.first {
            if !firstMenu.menu.menuImageUrl.isEmpty {
                menuImageView.loadImage(from: firstMenu.menu.menuImageUrl)
            }

            // Menu name
            let totalCount = order.orderMenuList.reduce(0) { $0 + $1.quantity }
            if totalCount > 1 {
                menuNameLabel.text = "\(firstMenu.menu.name) 외 \(totalCount - 1)개"
            } else {
                menuNameLabel.text = firstMenu.menu.name
            }
        }

        storeNameLabel.text = order.store.name

        // Date
        dateLabel.text = formatDate(order.createdAt)

        // Price
        priceLabel.text = "\(formatPrice(order.totalPrice))원"
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }

    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: dateString) else {
            // Fallback to basic ISO8601 format
            let basicFormatter = ISO8601DateFormatter()
            guard let date = basicFormatter.date(from: dateString) else { return dateString }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy년 M월 d일 a h:mm"
            return formatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 a h:mm"
        return formatter.string(from: date)
    }
}
