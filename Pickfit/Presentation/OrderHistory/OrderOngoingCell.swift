//
//  OrderOngoingCell.swift
//  Pickfit
//
//  Created by 김진수 on 2025-10-19.
//

import UIKit
import SnapKit
import Then

final class OrderOngoingCell: UITableViewCell {

    // MARK: - UI Components

    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    private let orderCodeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .black
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private let storeNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .black
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private let orderDateLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .systemGray
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private let storeImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    // Timeline Container
    private let timelineStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.distribution = .fillEqually
    }

    // Separator
    private let separatorLine = UIView().then {
        $0.backgroundColor = .systemGray5
    }

    // Menu Items Container
    private let menuStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
        $0.distribution = .fill
    }

    // Total Price
    private let totalPriceLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
        $0.textAlignment = .right
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
        containerView.addSubview(orderCodeLabel)
        containerView.addSubview(storeNameLabel)
        containerView.addSubview(orderDateLabel)
        containerView.addSubview(storeImageView)
        containerView.addSubview(timelineStack)
        containerView.addSubview(separatorLine)
        containerView.addSubview(menuStack)
        containerView.addSubview(totalPriceLabel)

        containerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-8)
        }

        // 좌측: 주문번호, 가게명, 이미지
        orderCodeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }

        storeNameLabel.snp.makeConstraints {
            $0.top.equalTo(orderCodeLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }

        orderDateLabel.snp.makeConstraints {
            $0.top.equalTo(storeNameLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(16)
        }

        storeImageView.snp.makeConstraints {
            $0.top.equalTo(orderDateLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(16)
            $0.width.equalTo(140)
            $0.height.equalTo(180)
        }

        // 우측: 타임라인
        timelineStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.lessThanOrEqualTo(storeImageView.snp.bottom)
        }

        separatorLine.snp.makeConstraints {
            $0.top.equalTo(timelineStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }

        menuStack.snp.makeConstraints {
            $0.top.equalTo(separatorLine.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        totalPriceLabel.snp.makeConstraints {
            $0.top.equalTo(menuStack.snp.bottom).offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-16)
        }
    }

    func configure(with order: OrderHistoryEntity) {
        orderCodeLabel.text = "주문번호 \(order.orderCode)"
        storeNameLabel.text = order.store.name
        orderDateLabel.text = formatOrderDate(order.createdAt)

        // Store image (TwoTone 이미지)
        storeImageView.image = UIImage(named: "truck")

        // Clear previous timeline
        timelineStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add timeline items
        for (index, timeline) in order.orderStatusTimeline.enumerated() {
            let isLast = (index == order.orderStatusTimeline.count - 1)
            let nextCompleted = !isLast && order.orderStatusTimeline[index + 1].completed
            let itemView = createTimelineItem(timeline: timeline, isLast: isLast, nextCompleted: nextCompleted)
            timelineStack.addArrangedSubview(itemView)
        }

        // Clear previous menu items
        menuStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add menu items
        for (index, menuItem) in order.orderMenuList.enumerated() {
            let menuView = createMenuItem(menu: menuItem.menu, quantity: menuItem.quantity)
            menuStack.addArrangedSubview(menuView)
        }

        // Total price
        totalPriceLabel.text = "합계 \(formatPrice(order.totalPrice))원"
    }

    // MARK: - Timeline Item

    private func createTimelineItem(timeline: OrderStatusEntity, isLast: Bool, nextCompleted: Bool) -> UIView {
        let container = UIView()

        // Icon (checkmark.circle.fill or circle)
        let iconView = UIImageView().then {
            $0.contentMode = .scaleAspectFit
            if timeline.completed {
                $0.image = UIImage(systemName: "checkmark.circle.fill")
                $0.tintColor = .systemGreen
            } else {
                let config = UIImage.SymbolConfiguration(weight: .heavy)
                $0.image = UIImage(systemName: "circle", withConfiguration: config)
                $0.tintColor = .systemGray4
            }
        }

        // Connector line (연결선) - 마지막 아이템이 아니면 표시
        if !isLast {
            let connectorLine = UIView().then {
                // 다음 단계가 완료되었으면 초록색, 아니면 회색
                $0.backgroundColor = nextCompleted ? .systemGreen : .systemGray4
            }
            container.addSubview(connectorLine)
            container.addSubview(iconView) // iconView를 나중에 추가하여 상위 계층에 배치

            connectorLine.snp.makeConstraints {
                $0.centerX.equalTo(iconView) // iconView 중앙에 정렬
                $0.top.equalTo(iconView.snp.bottom).offset(-3)
                $0.bottom.equalToSuperview().offset(14)
                $0.width.equalTo(4)
            }
        } else {
            container.addSubview(iconView)
        }

        // Status label
        let statusLabel = UILabel().then {
            $0.text = timeline.status.displayText
            $0.font = .systemFont(ofSize: 14, weight: timeline.completed ? .semibold : .regular)
            $0.textColor = timeline.completed ? .black : .systemGray3
        }

        // Time label (우측)
        let timeLabel = UILabel().then {
            if let changedAt = timeline.changedAt, !changedAt.isEmpty {
                $0.text = formatTime(changedAt)
            } else {
                $0.text = ""
            }
            $0.font = .systemFont(ofSize: 12, weight: .regular)
            $0.textColor = .systemGray2
            $0.textAlignment = .right
        }

        container.addSubview(statusLabel)
        container.addSubview(timeLabel)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview()
            $0.width.height.equalTo(20)
        }

        statusLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.centerY.equalTo(iconView)
        }

        timeLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-10)
            $0.centerY.equalTo(iconView)
            $0.leading.greaterThanOrEqualTo(statusLabel.snp.trailing).offset(12)
        }

        container.snp.makeConstraints {
            $0.height.equalTo(40)
        }

        return container
    }

    // MARK: - Menu Item

    private func createMenuItem(menu: OrderMenuDetailEntity, quantity: Int) -> UIView {
        let container = UIView()

        // 메뉴 이미지
        let menuImageView = ImageLoadView(cornerRadius: 6).then {
            $0.backgroundColor = .systemGray6
        }

        let nameLabel = UILabel().then {
            $0.text = menu.name
            $0.font = .systemFont(ofSize: 14, weight: .medium)
            $0.textColor = .darkGray
        }

        let quantityLabel = UILabel().then {
            $0.text = "\(quantity)개"
            $0.font = .systemFont(ofSize: 13, weight: .regular)
            $0.textColor = .systemGray
        }

        let priceLabel = UILabel().then {
            $0.text = "\(formatPrice(menu.price * quantity))원"
            $0.font = .systemFont(ofSize: 14, weight: .semibold)
            $0.textColor = .black
            $0.textAlignment = .right
        }

        container.addSubview(menuImageView)
        container.addSubview(nameLabel)
        container.addSubview(quantityLabel)
        container.addSubview(priceLabel)

        // 메뉴 이미지 로드
        if !menu.menuImageUrl.isEmpty {
            menuImageView.loadImage(from: menu.menuImageUrl)
        }

        menuImageView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.width.height.equalTo(50)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(menuImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview()
        }

        quantityLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        return container
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }

    private func formatTime(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: dateString) else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatOrderDate(_ dateString: String) -> String {
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
