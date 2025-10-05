//
//  StoreHeaderView.swift
//  Pickfit
//
//  Created by 김진수 on 10/5/25.
//

import UIKit
import SnapKit
import Then

final class StoreHeaderView: UICollectionReusableView {
    static let reuseID = "StoreHeaderView"

    // MARK: - UI Components
    private let logoImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 30
        $0.image = UIImage(named: "modimood_logo") // placeholder
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .black
        $0.text = "모디무드"
    }

    private let subtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .medium)
        $0.textColor = .gray
        $0.text = "마켓 찜 201.4만  |  상품 찜 617.4만  |  만족도 95%"
    }

    private let likeButton = UIButton(type: .system).then {
        $0.setTitle("마켓 찜하기", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        $0.backgroundColor = UIColor(red: 1.0, green: 0.29, blue: 0.33, alpha: 1)
        $0.layer.cornerRadius = 8
    }

    private let infoButton = UIButton(type: .system).then {
        let image = UIImage(systemName: "info.circle")
        $0.setImage(image, for: .normal)
        $0.tintColor = .lightGray
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup
    private func configureHierarchy() {
        [logoImageView, titleLabel, subtitleLabel, likeButton, infoButton].forEach {
            addSubview($0)
        }
    }

    private func configureLayout() {
        logoImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.width.height.equalTo(60)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(logoImageView.snp.top).offset(4)
            $0.leading.equalTo(logoImageView.snp.trailing).offset(12)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        likeButton.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().inset(20)
        }

        infoButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.height.equalTo(20)
        }
    }

    // MARK: - Configure
    func configure(with store: StoreDetailEntity) {
        // TODO: logoImageView는 나중에 실제 이미지 로딩으로 대체
        titleLabel.text = store.name

        // pickCount를 표시 (만 단위로 변환)
        let pickCountFormatted = formatCount(store.pickCount)

        // 평점을 만족도처럼 표시 (5점 만점을 100점 만점으로 환산)
        let satisfaction = Int((store.totalRating / 5.0) * 100)

        subtitleLabel.text = "마켓 찜 \(pickCountFormatted)  |  리뷰 \(store.totalReviewCount)  |  만족도 \(satisfaction)%"
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            let manCount = Double(count) / 10000.0
            return String(format: "%.1f만", manCount)
        } else {
            return "\(count)"
        }
    }
}
