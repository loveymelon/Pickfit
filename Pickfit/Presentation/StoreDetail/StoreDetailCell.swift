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
    private let imageLoadView = ImageLoadView(contentMode: .scaleToFill)
    
//    private let detailLabel = UILabel().then {
//        $0.font = .systemFont(ofSize: 20, weight: .bold)
//        $0.textColor = .white
//        $0.numberOfLines = 0
//        $0.text = "fasdjfkljasdkl"
//    }

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

    func configure(with imageUrl: String) {
        imageLoadView.loadImage(from: imageUrl)
    }
}

extension StoreDetailCell: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
    }

    func configureHierarchy() {
        contentView.addSubview(imageLoadView)
//        contentView.addSubview(detailLabel)
    }

    func configureLayout() {
        imageLoadView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
//        detailLabel.snp.makeConstraints {
//            $0.leading.equalToSuperview()
//            $0.bottom.equalToSuperview()
//        }
    }
}
