//
//  CommunityCell.swift
//  Pickfit
//
//  Created by Claude on 2025-10-20.
//

import UIKit
import SnapKit
import Then

final class CommunityCell: UICollectionViewCell {

    private let imageView = ImageLoadView(cornerRadius: 12)

    private let gradientView = UIView().then {
        $0.backgroundColor = .clear
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .white
        $0.numberOfLines = 2
    }

    private let userNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .white.withAlphaComponent(0.9)
    }

    private let likeButton = UIButton().then {
        $0.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        $0.tintColor = .white
        $0.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        $0.setTitleColor(.white, for: .normal)
    }

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientView.bounds
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(gradientView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(likeButton)

        // Gradient 설정
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        gradientLayer.locations = [0.5, 1.0]
        gradientView.layer.addSublayer(gradientLayer)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        gradientView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(100)
        }

        likeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.bottom.equalToSuperview().offset(-12)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.equalTo(likeButton.snp.leading).offset(-8)
            $0.bottom.equalTo(userNameLabel.snp.top).offset(-4)
        }

        userNameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.equalTo(likeButton.snp.leading).offset(-8)
            $0.bottom.equalToSuperview().offset(-12)
        }

        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
    }

    func configure(with item: CommunityItem) {
        imageView.loadImage(from: item.imageUrl)
        titleLabel.text = item.title
        userNameLabel.text = "@\(item.userName)"
        likeButton.setTitle(" \(item.likeCount)", for: .normal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelLoading()
    }
}
