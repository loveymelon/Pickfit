//
//  CommunityView.swift
//  Pickfit
//
//  Created by 김진수 on 2025-10-20.
//

import UIKit
import SnapKit
import Then

final class CommunityView: BaseView {

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.showsVerticalScrollIndicator = true
        return cv
    }()

    let titleLabel = UILabel().then {
        $0.text = "커뮤니티"
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .black
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
            $0.edges.equalTo(safeAreaLayoutGuide)
        }
    }

    override func configureUI() {
        super.configureUI()
        backgroundColor = .systemBackground
    }
}
