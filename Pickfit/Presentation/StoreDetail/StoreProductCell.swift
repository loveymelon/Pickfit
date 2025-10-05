//
//  StoreProductCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/5/25.
//

import UIKit
import SnapKit
import Then

final class StoreProductCell: UICollectionViewCell {
    // MARK: - UI Components
    private let imageLoadView = ImageLoadView(cornerRadius: 10, contentMode: .scaleAspectFill)

    private let likeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        $0.tintColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        $0.layer.cornerRadius = 16
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .label
        $0.numberOfLines = 2
        $0.lineBreakMode = .byTruncatingTail
    }

    private let priceLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 17, weight: .bold)
        $0.textColor = .label
    }

    private let discountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 17, weight: .bold)
        $0.textColor = UIColor(red: 0.95, green: 0.18, blue: 0.2, alpha: 1)
    }

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadView.cancelLoading()
        likeButton.isSelected = false
        titleLabel.text = nil
        priceLabel.text = nil
        discountLabel.text = nil
    }

    // MARK: - Configure
    func configure(with product: ProductModel) {
        imageLoadView.loadImage(from: product.imageUrl)
        titleLabel.text = product.title
        priceLabel.text = product.priceText

        if let discount = product.discountPercent {
            discountLabel.text = "\(discount)%"
            discountLabel.isHidden = false
        } else {
            discountLabel.isHidden = true
        }

        likeButton.isSelected = product.isLiked
    }
}

extension StoreProductCell: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
    }

    func configureHierarchy() {
        contentView.addSubview(imageLoadView)
        imageLoadView.addSubview(likeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(discountLabel)
        contentView.addSubview(priceLabel)
    }

    func configureLayout() {
        imageLoadView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(imageLoadView.snp.width)
        }

        likeButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.trailing.equalToSuperview().inset(8)
            $0.width.height.equalTo(32)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(imageLoadView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }

        discountLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview()
        }

        priceLabel.snp.makeConstraints {
            $0.centerY.equalTo(discountLabel)
            $0.leading.equalTo(discountLabel.snp.trailing).offset(4)
            $0.trailing.lessThanOrEqualToSuperview()
        }
    }
}

// MARK: - ProductModel
struct ProductModel {
    let imageUrl: String?
    let title: String
    let priceText: String
    let discountPercent: Int?
    let isLiked: Bool
}
