//
//  OrderHistoryRowCell.swift
//  Pickfit
//
//  Created by 김진수 on 2025-10-19.
//

import UIKit
import SnapKit
import Then

final class OrderHistoryRowCell: UITableViewCell {

    // MARK: - UI Components

    private let containerView = UIView().then {
        $0.backgroundColor = .white
    }

    private let cardView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray5.cgColor
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    private let separatorLine = UIView().then {
        $0.backgroundColor = .systemGray5
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

    private let reviewSeparatorLine = UIView().then {
        $0.backgroundColor = .systemGray5
        $0.isHidden = true
    }

    private let writeReviewButton = UIButton(type: .system).then {
        $0.setTitle("리뷰 작성하기", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray5.cgColor
        $0.contentHorizontalAlignment = .center
        $0.isHidden = true
    }

    private let reviewChevronImageView = UIImageView().then {
        $0.image = UIImage(systemName: "chevron.right")
        $0.tintColor = .systemGray3
        $0.contentMode = .scaleAspectFit
    }

    private var currentOrder: OrderHistoryEntity?
    var onWriteReviewTapped: ((OrderHistoryEntity) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(cardView)
        cardView.addSubview(storeNameLabel)
        cardView.addSubview(menuImageView)
        cardView.addSubview(dateLabel)
        cardView.addSubview(menuNameLabel)
        cardView.addSubview(priceLabel)
        cardView.addSubview(chevronImageView)
        cardView.addSubview(separatorLine)
        cardView.addSubview(reviewSeparatorLine)
        cardView.addSubview(writeReviewButton)
        writeReviewButton.addSubview(reviewChevronImageView)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        cardView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(-8)
        }

        separatorLine.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        storeNameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(12)
            $0.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-8)
        }

        menuImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.equalTo(storeNameLabel.snp.top)
            $0.width.height.equalTo(50)
        }
        
        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(storeNameLabel)
            $0.top.equalTo(storeNameLabel.snp.bottom).offset(2)
        }

        menuNameLabel.snp.makeConstraints {
            $0.leading.equalTo(storeNameLabel)
            $0.top.equalTo(dateLabel.snp.bottom).offset(4)
            $0.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-8)
        }

        priceLabel.snp.makeConstraints {
            $0.leading.equalTo(menuNameLabel.snp.trailing).offset(4)
            $0.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-8)
            $0.top.equalTo(menuNameLabel.snp.top)
        }

        chevronImageView.snp.makeConstraints {
            $0.leading.equalTo(priceLabel.snp.trailing).offset(4)
            $0.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-8)
            $0.width.height.equalTo(14)
            $0.top.equalTo(priceLabel.snp.top)
        }

        reviewSeparatorLine.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.equalTo(menuNameLabel.snp.bottom).offset(8)
            $0.height.equalTo(0.5)
        }

        writeReviewButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.equalTo(reviewSeparatorLine.snp.bottom).offset(8)
            $0.height.equalTo(36)
            $0.bottom.equalToSuperview().offset(-12)
        }

        reviewChevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(12)
        }
    }

    private func setupActions() {
        writeReviewButton.addTarget(self, action: #selector(handleWriteReviewTapped), for: .touchUpInside)
    }

    @objc private func handleWriteReviewTapped() {
        guard let order = currentOrder else { return }
        onWriteReviewTapped?(order)
    }

    func configure(with order: OrderHistoryEntity) {
        self.currentOrder = order
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

        // Review button visibility
        let shouldShowReviewButton = (order.currentOrderStatus == .pickedUp && order.review == nil)
        reviewSeparatorLine.isHidden = !shouldShowReviewButton
        writeReviewButton.isHidden = !shouldShowReviewButton

        // Update menuNameLabel bottom constraint
        menuNameLabel.snp.remakeConstraints {
            $0.leading.equalTo(storeNameLabel)
            $0.top.equalTo(dateLabel.snp.bottom).offset(4)
            $0.trailing.lessThanOrEqualTo(menuImageView.snp.leading).offset(-8)

            if !shouldShowReviewButton {
                $0.bottom.equalToSuperview().offset(-12)
            }
        }
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
