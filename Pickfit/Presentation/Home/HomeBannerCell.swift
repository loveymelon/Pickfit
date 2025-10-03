//
//  HomeBannerCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import SnapKit
import Then

final class HomeBannerCell: UICollectionViewCell {
    private let imageLoadView = ImageLoadView(cornerRadius: 12, contentMode: .scaleToFill)

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

    func configure(with banner: BannerResponseDTO.Banner) {
        imageLoadView.loadImage(from: banner.imageUrl)
    }
}

extension HomeBannerCell: UIConfigureProtocol {
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
