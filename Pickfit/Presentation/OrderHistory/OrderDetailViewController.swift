//
//  OrderDetailViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import UIKit
import SnapKit
import Then

final class OrderDetailViewController: UIViewController {

    private let order: OrderHistoryEntity

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Header
    private let headerView = UIView().then {
        $0.backgroundColor = .white
    }

    private let statusIconView = UIView().then {
        $0.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        $0.layer.cornerRadius = 30
    }

    private let statusIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "shippingbox")
        $0.tintColor = .systemBlue
        $0.contentMode = .scaleAspectFit
    }

    private let statusTitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textAlignment = .center
    }

    private let statusDescriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .systemGray
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }

    // Timeline
    private let timelineTableView = UITableView().then {
        $0.backgroundColor = .white
        $0.separatorStyle = .none
        $0.isScrollEnabled = false
        $0.register(OrderStatusTimelineCell.self, forCellReuseIdentifier: OrderStatusTimelineCell.identifier)
    }

    // Order Info
    private let orderInfoView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
    }

    private let orderInfoTitleLabel = UILabel().then {
        $0.text = "주문 정보"
        $0.font = .systemFont(ofSize: 16, weight: .bold)
    }

    private let orderCodeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .darkGray
    }

    private let storeNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .darkGray
    }

    private let totalPriceLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
    }

    init(order: OrderHistoryEntity) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureData()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "주문 상세"

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerView)
        headerView.addSubview(statusIconView)
        statusIconView.addSubview(statusIconImageView)
        headerView.addSubview(statusTitleLabel)
        headerView.addSubview(statusDescriptionLabel)

        contentView.addSubview(timelineTableView)
        contentView.addSubview(orderInfoView)
        orderInfoView.addSubview(orderInfoTitleLabel)
        orderInfoView.addSubview(orderCodeLabel)
        orderInfoView.addSubview(storeNameLabel)
        orderInfoView.addSubview(totalPriceLabel)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(180)
        }

        statusIconView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(24)
            $0.width.height.equalTo(60)
        }

        statusIconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(32)
        }

        statusTitleLabel.snp.makeConstraints {
            $0.top.equalTo(statusIconView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        statusDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(statusTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        timelineTableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(calculateTimelineHeight())
        }

        orderInfoView.snp.makeConstraints {
            $0.top.equalTo(timelineTableView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-20)
        }

        orderInfoTitleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
        }

        orderCodeLabel.snp.makeConstraints {
            $0.top.equalTo(orderInfoTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        storeNameLabel.snp.makeConstraints {
            $0.top.equalTo(orderCodeLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        totalPriceLabel.snp.makeConstraints {
            $0.top.equalTo(storeNameLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-16)
        }

        timelineTableView.dataSource = self
    }

    private func configureData() {
        // Status
        statusTitleLabel.text = order.currentOrderStatus.displayText
        statusDescriptionLabel.text = order.currentOrderStatus.detailText

        updateStatusIcon(for: order.currentOrderStatus)

        // Order Info
        orderCodeLabel.text = "주문번호: \(order.orderCode)"
        storeNameLabel.text = "가게: \(order.store.name)"
        totalPriceLabel.text = "총 결제금액: \(formatPrice(order.totalPrice))원"
    }

    private func updateStatusIcon(for status: OrderStatus) {
        let (icon, color) = statusIconConfig(for: status)
        statusIconImageView.image = UIImage(systemName: icon)
        statusIconImageView.tintColor = color
        statusIconView.backgroundColor = color.withAlphaComponent(0.1)
    }

    private func statusIconConfig(for status: OrderStatus) -> (String, UIColor) {
        switch status {
        case .pendingApproval:
            return ("clock", .systemOrange)
        case .approved:
            return ("checkmark.circle", .systemBlue)
        case .inProgress:
            return ("shippingbox", .systemPurple)
        case .readyForPickup:
            return ("bag", .systemGreen)
        case .pickedUp:
            return ("checkmark.circle.fill", .systemGray)
        case .cancelled:
            return ("xmark.circle", .systemRed)
        }
    }

    private func calculateTimelineHeight() -> CGFloat {
        let cellHeight: CGFloat = 80
        return CGFloat(order.orderStatusTimeline.count) * cellHeight
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}

// MARK: - UITableViewDataSource
extension OrderDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return order.orderStatusTimeline.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OrderStatusTimelineCell.identifier,
            for: indexPath
        ) as? OrderStatusTimelineCell else {
            return UITableViewCell()
        }

        let statusEntity = order.orderStatusTimeline[indexPath.row]
        let isLast = indexPath.row == order.orderStatusTimeline.count - 1
        cell.configure(with: statusEntity, isLast: isLast)

        return cell
    }
}
