//
//  StoreDetailCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import SnapKit
import Then

final class StoreDetailCell: UICollectionViewCell {
    private let imageLoadView = ImageLoadView(cornerRadius: 20)

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
    }

    func configure(with store: StoreEntity) {
        imageLoadView.loadImage(from: store.storeImageUrls.first)
    }
}

extension StoreDetailCell: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
    }

    func configureHierarchy() {
        contentView.addSubview(imageLoadView)
    }

    func configureLayout() {
        imageLoadView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
