//
//  ProductDetailView.swift
//  Pickfit
//
//  Created by 김진수 on 10/6/25.
//

import UIKit
import SnapKit
import Then

final class ProductDetailView: BaseView {
    let collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()).then {
        $0.backgroundColor = .white
        $0.register(StoreDetailCell.self, forCellWithReuseIdentifier: StoreDetailCell.identifier)
    }

    let testLabel = UILabel().then {
        $0.text = "Product Detail"
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(testLabel)
        addSubview(collectionView)
    }

    override func configureLayout() {
        testLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(testLabel.snp.bottom).offset(20)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func configureUI() {
        backgroundColor = .white
    }
}
