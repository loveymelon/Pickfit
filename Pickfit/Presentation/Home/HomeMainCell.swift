//
//  HomeMainCell.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit
import Then
import SnapKit

final class HomeMainCell: UICollectionViewCell {
    let storeImageView = UIImageView().then {
        $0.clipsToBounds = true
        $0.contentMode = .scaleToFill
        $0.layer.cornerRadius = 20
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomeMainCell: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
    }
    
    func configureHierarchy() {
        contentView.addSubview(storeImageView)
    }
    
    func configureLayout() {
        storeImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
