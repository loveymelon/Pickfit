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
    // 로고 + 앱 이름
    private let logoImageView = UIImageView().then {
        $0.image = UIImage(systemName: "bag.fill")  // 임시 아이콘 (실제 로고로 교체 필요)
        $0.tintColor = .systemBlue
        $0.contentMode = .scaleAspectFit
    }

    private let appNameLabel = UILabel().then {
        $0.text = "Pickfit"
        $0.font = .systemFont(ofSize: 36, weight: .bold)
        $0.textColor = .black
        $0.textAlignment = .center
    }

    let emailLoginButton = UIButton(type: .system).then {
        $0.setTitle("이메일로 로그인", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .systemBlue
        $0.layer.cornerRadius = 12
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    }

    private let dividerView = UIView().then {
        $0.backgroundColor = .systemGray4
    }

    private let dividerLabel = UILabel().then {
        $0.text = "또는"
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .systemGray
        $0.backgroundColor = .white
        $0.textAlignment = .center
    }

    let kakaoSignInButton = UIButton().then {
        $0.backgroundColor = .clear
//        $0.layer.cornerRadius = 5
//        $0.layer.borderWidth = 1
//        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.setTitle("카카오 로그인", for: .normal)
        $0.setImage(UIImage(named: "KakaoLogin"), for: .normal)
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
        addSubview(logoImageView)
        addSubview(appNameLabel)
        addSubview(emailLoginButton)
        addSubview(dividerView)
        addSubview(dividerLabel)
        addSubview(kakaoSignInButton)
        addSubview(appleSignInButton)
    }

    override func configureLayout() {
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(safeAreaLayoutGuide).offset(100)
            make.width.height.equalTo(80)
        }

        appNameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImageView.snp.bottom).offset(16)
        }

        emailLoginButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(appNameLabel.snp.bottom).offset(80)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
            make.height.equalTo(52)
        }

        dividerView.snp.makeConstraints { make in
            make.top.equalTo(emailLoginButton.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
            make.height.equalTo(1)
        }

        dividerLabel.snp.makeConstraints { make in
            make.centerY.equalTo(dividerView)
            make.centerX.equalToSuperview()
            make.width.equalTo(50)
        }

        kakaoSignInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(dividerView.snp.bottom).offset(24)
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
