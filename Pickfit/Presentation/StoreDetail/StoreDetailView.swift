//
//  StoreDetailView.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import SnapKit
import Then

final class StoreDetailView: BaseView {
    let collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()).then {
        $0.backgroundColor = .white
        $0.register(StoreDetailCell.self, forCellWithReuseIdentifier: StoreDetailCell.identifier)
        $0.register(StoreProductCell.self, forCellWithReuseIdentifier: StoreProductCell.identifier)
        $0.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        $0.register(StoreHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StoreHeaderView.reuseID)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(collectionView)
    }

    override func configureLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func configureUI() {
        super.configureUI()
        // CollectionView가 safeArea 무시하고 최상단까지 올라가도록 설정
        collectionView.contentInsetAdjustmentBehavior = .never
    }
}
