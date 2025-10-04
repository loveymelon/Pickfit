//
//  StoreCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class StoreCell: UICollectionViewCell {
    private var disposeBag = DisposeBag()

    private let logoImageView = ImageLoadView(cornerRadius: 20, contentMode: .scaleAspectFill)

    private let nameLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 16)
    }

    private let tagsLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .gray
        $0.lineBreakMode = .byTruncatingTail
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = false
        $0.minimumScaleFactor = 1.0
    }

    private let likeButton = UIButton().then {
        $0.setImage(UIImage(named: "Like"), for: .normal)
        $0.setImage(UIImage(named: "LikeFill"), for: .selected)
        $0.tintColor = .red
    }

    private let productImageViews: [ImageLoadView] = (0..<3).map { _ in
        ImageLoadView(cornerRadius: 8, contentMode: .scaleAspectFill)
    }

    private lazy var productStackView: UIStackView = {
        UIStackView(arrangedSubviews: productImageViews).then {
            $0.axis = .horizontal
            $0.spacing = 10
            $0.distribution = .fillEqually
        }
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        logoImageView.cancelLoading()
        productImageViews.forEach { $0.cancelLoading() }

        // 라벨 초기화
        nameLabel.text = nil
        tagsLabel.text = nil
    }

    func configure(with store: StoreResponseDTO.Store, at index: Int, reactor: StoreListReactor) {
        nameLabel.text = store.name
        tagsLabel.text = store.hashTags.joined(separator: " ")
        likeButton.isSelected = store.isPicchelin

        // 로고 이미지 (첫 번째 이미지)
        logoImageView.loadImage(from: store.storeImageUrls.first)

        // 상품 이미지들 (최대 3개)
        for (i, imageView) in productImageViews.enumerated() {
            if i < store.storeImageUrls.count {
                imageView.loadImage(from: store.storeImageUrls[i])
            }
        }

        // Like button tap binding
        likeButton.rx.tap
            .map { StoreListReactor.Action.toggleLike(index: index) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
}

extension StoreCell: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
    }

    func configureHierarchy() {
        contentView.addSubview(logoImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(tagsLabel)
        contentView.addSubview(likeButton)
        contentView.addSubview(productStackView)
    }

    func configureLayout() {
        logoImageView.snp.makeConstraints {
            $0.leading.top.equalToSuperview().inset(12)
            $0.size.equalTo(40)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(logoImageView)
            $0.leading.equalTo(logoImageView.snp.trailing).offset(8)
        }

        tagsLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
        }

        likeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalTo(logoImageView)
        }

        productStackView.snp.makeConstraints {
            $0.top.equalTo(logoImageView.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(12)
            $0.height.equalTo(160)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }
}
