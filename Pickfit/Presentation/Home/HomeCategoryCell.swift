//
//  HomeCategoryCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import SnapKit
import Then

final class HomeCategoryCell: UICollectionViewCell {
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 30
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textAlignment = .center
        $0.textColor = .label
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with category: Category) {
        imageView.image = UIImage(named: category.imageName)
        titleLabel.text = category.displayName
    }
}

extension HomeCategoryCell: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
    }

    func configureHierarchy() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
    }

    func configureLayout() {
        imageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(60)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(4)
            $0.bottom.lessThanOrEqualToSuperview().offset(-8)
        }
    }
}
