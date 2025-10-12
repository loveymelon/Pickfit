//
//  OrderStatusTimelineCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import UIKit
import SnapKit
import Then

final class OrderStatusTimelineCell: UITableViewCell {

    private let stepCircle = UIView().then {
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 2
    }

    private let checkmarkImageView = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark")
        $0.tintColor = .white
        $0.contentMode = .scaleAspectFit
        $0.isHidden = true
    }

    private let verticalLine = UIView()

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .semibold)
    }

    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .systemGray
        $0.numberOfLines = 0
    }

    private let dateLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .systemGray2
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

        contentView.addSubview(stepCircle)
        stepCircle.addSubview(checkmarkImageView)
        contentView.addSubview(verticalLine)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(dateLabel)

        stepCircle.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(12)
            $0.width.height.equalTo(24)
        }

        checkmarkImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(12)
        }

        verticalLine.snp.makeConstraints {
            $0.centerX.equalTo(stepCircle)
            $0.top.equalTo(stepCircle.snp.bottom)
            $0.bottom.equalToSuperview()
            $0.width.equalTo(2)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(stepCircle.snp.trailing).offset(16)
            $0.top.equalTo(stepCircle)
            $0.trailing.equalToSuperview().offset(-20)
        }

        descriptionLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.trailing.equalTo(titleLabel)
        }

        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    func configure(with statusEntity: OrderStatusEntity, isLast: Bool) {
        titleLabel.text = statusEntity.status.displayText
        descriptionLabel.text = statusEntity.status.detailText

        if statusEntity.completed {
            // 완료된 상태
            stepCircle.backgroundColor = .systemBlue
            stepCircle.layer.borderColor = UIColor.systemBlue.cgColor
            checkmarkImageView.isHidden = false
            titleLabel.textColor = .black
            verticalLine.backgroundColor = .systemBlue

            if let changedAt = statusEntity.changedAt {
                dateLabel.text = formatDate(changedAt)
                dateLabel.isHidden = false
            } else {
                dateLabel.isHidden = true
            }
        } else {
            // 대기 중인 상태
            stepCircle.backgroundColor = .white
            stepCircle.layer.borderColor = UIColor.systemGray4.cgColor
            checkmarkImageView.isHidden = true
            titleLabel.textColor = .systemGray
            verticalLine.backgroundColor = .systemGray5

            dateLabel.isHidden = true
        }

        // 마지막 셀은 세로선 숨김
        verticalLine.isHidden = isLast
    }

    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: dateString) else { return dateString }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd HH:mm"
        return formatter.string(from: date)
    }
}
