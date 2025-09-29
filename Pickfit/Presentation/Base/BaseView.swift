//
//  BaseView.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit

class BaseView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BaseView: UIConfigure {
    func configureUI() {
        backgroundColor = .white
        
        configureHierarchy()
        configureLayout()
    }
    
    func configureHierarchy() {
        
    }
    
    func configureLayout() {
        
    }
}
