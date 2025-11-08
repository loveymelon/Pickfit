//
//  OrderBannerCell.swift
//  Pickfit
//
//  Created by 김진수 on 2025-10-19.
//

import UIKit
import SnapKit
import Then

final class OrderBannerCell: UITableViewCell {

    private let containerView = UIView().then {
        $0.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        $0.layer.cornerRadius = 12
    }

    private let messageLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .systemGreen
        $0.numberOfLines = 2
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

        contentView.addSubview(containerView)
        containerView.addSubview(messageLabel)

        containerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-4)
            $0.height.equalTo(60)
        }

        messageLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    func configure(with message: String) {
        messageLabel.text = message
    }
}
