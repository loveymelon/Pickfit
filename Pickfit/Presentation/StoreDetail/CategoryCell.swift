//
//  CategoryCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/5/25.
//

import UIKit
import SnapKit
import Then

final class CategoryCell: UICollectionViewCell {
    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textAlignment = .center
    }

    // MARK: - Properties
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(with title: String) {
        titleLabel.text = title
        updateAppearance()
    }

    private func updateAppearance() {
        titleLabel.textColor = isSelected ? .white : .darkGray
        contentView.backgroundColor = isSelected ? .black : .systemGray5
    }
}

extension CategoryCell: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        contentView.backgroundColor = .systemGray5
    }

    func configureHierarchy() {
        contentView.addSubview(titleLabel)
    }

    func configureLayout() {
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
        }
    }
}
