//
//  CommunityCell.swift
//  Pickfit
//
//  Created by 김진수 on 2025-10-20.
//

import UIKit
import SnapKit
import Then

final class CommunityCell: UICollectionViewCell {

    private let imageView = ImageLoadView(cornerRadius: 12)

    private let gradientView = UIView().then {
        $0.backgroundColor = .clear
    }

    private let playButtonOverlay = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        $0.isHidden = true
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let playIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "play.circle.fill")
        $0.tintColor = .white
        $0.contentMode = .scaleAspectFit
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
        updateGradientFrame()
    }

    private func updateGradientFrame() {
        gradientLayer.frame = gradientView.bounds
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(playButtonOverlay)
        playButtonOverlay.addSubview(playIconImageView)
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

        playButtonOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        playIconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(60)
        }

        gradientView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(100)
        }

        likeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.bottom.equalTo(userNameLabel)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.bottom.equalTo(userNameLabel.snp.top).offset(-4)
        }

        userNameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().offset(-12)
        }

        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        // Shadow configuration
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false

        // Gradient corner radius
        gradientLayer.cornerRadius = 12
        gradientLayer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }

    func configure(with item: CommunityItem) {
        // 동영상이면 썸네일 생성, 이미지면 바로 로드
        if item.isVideo {
            imageView.loadVideoThumbnail(from: item.imageUrl)
        } else {
            imageView.loadImage(from: item.imageUrl)
        }

        titleLabel.text = item.title
        userNameLabel.text = "@\(item.userName)"
        likeButton.setTitle(" \(item.likeCount)", for: .normal)

        // 동영상이면 재생 버튼 오버레이 표시
        playButtonOverlay.isHidden = !item.isVideo

        // Force layout and update gradient immediately
        layoutIfNeeded()
        updateGradientFrame()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelLoading()
    }
}
