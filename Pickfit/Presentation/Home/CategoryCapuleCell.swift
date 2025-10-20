//
//  CategoryCapuleCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/16/25.
//

import UIKit

final class CategoryCapsuleCell: UICollectionViewCell {
    
    private let iconImageView = ImageLoadView(cornerRadius: 10, contentMode: .scaleAspectFit)

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .darkGray
    }

    private let containerView = UIView().then {
        $0.layer.cornerRadius = 18
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
        $0.backgroundColor = .white
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(image: String?, text: String, isSelected: Bool = false) {
        iconImageView.loadImage(from: image)
        titleLabel.text = text
        updateSelectionState(isSelected: isSelected)
    }

    private func updateSelectionState(isSelected: Bool) {
        if isSelected {
            containerView.layer.borderWidth = 2
            containerView.layer.borderColor = UIColor.black.cgColor
            containerView.backgroundColor = UIColor.black.withAlphaComponent(0.05)
            titleLabel.textColor = .black
            titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        } else {
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            containerView.backgroundColor = .white
            titleLabel.textColor = .darkGray
            titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        }
    }
}

extension CategoryCapsuleCell: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
    }
    
    func configureHierarchy() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
    }
    
    func configureLayout() {
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(28)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
        }
    }
}
