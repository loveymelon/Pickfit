//
//  HomeView.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit
import Then
import SnapKit

final class HomeView: BaseView {
    let titleLabel = UILabel().then {
        $0.text = "Pickfit"
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .black
    }
    
    let searchButton = UIButton(type: .system).then {
        $0.setImage(UIImage(named: "Search"), for: .normal)
        $0.tintColor = .black
    }
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()).then {
        $0.backgroundColor = .white
        $0.register(HomeMainCell.self, forCellWithReuseIdentifier: HomeMainCell.identifier)
        $0.register(HomeCategoryCell.self, forCellWithReuseIdentifier: HomeCategoryCell.identifier)
        $0.register(HomeBannerCell.self, forCellWithReuseIdentifier: HomeBannerCell.identifier)
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
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
