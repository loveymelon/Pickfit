//
//  LoginView.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit
import Then
import SnapKit

final class LoginView: BaseView {
    let signInButton = UIButton().then {
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 5
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.setTitle("로그인", for: .normal)
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        $0.setTitleColor(.black, for: .normal)
        $0.isEnabled = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureHierarchy() {
        addSubview(signInButton)
    }
    
    override func configureLayout() {
      
        signInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(48)
        }
    }
}
