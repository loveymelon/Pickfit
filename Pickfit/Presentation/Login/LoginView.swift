//
//  LoginView.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit
import Then
import SnapKit
import AuthenticationServices

final class LoginView: BaseView {
    let kakaoSignInButton = UIButton().then {
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 5
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.setTitle("카카오 로그인", for: .normal)
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        $0.setTitleColor(.black, for: .normal)
        $0.isEnabled = true
    }

    let appleSignInButton = ASAuthorizationAppleIDButton(
        authorizationButtonType: .signIn,
        authorizationButtonStyle: .black
    ).then {
        $0.cornerRadius = 5
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureHierarchy() {
        addSubview(kakaoSignInButton)
        addSubview(appleSignInButton)
    }

    override func configureLayout() {
        kakaoSignInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
            make.height.equalTo(48)
        }

        appleSignInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(kakaoSignInButton.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
            make.height.equalTo(48)
        }
    }
}
