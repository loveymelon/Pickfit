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
    private let bannerImageViews: [ImageLoadView] = (0..<3).map { _ in
        ImageLoadView(cornerRadius: 8, contentMode: .scaleAspectFill)
    }
    
    private lazy var bannerStackView: UIStackView = {
        UIStackView(arrangedSubviews: bannerImageViews).then {
            $0.axis = .horizontal
            $0.spacing = 10
            $0.distribution = .fillEqually
        }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureHierarchy() {
        addSubview(bannerStackView)
    }

    override func configureLayout() {
//        collectionView.snp.makeConstraints {
//            $0.edges.equalToSuperview()
//        }
    }
}
