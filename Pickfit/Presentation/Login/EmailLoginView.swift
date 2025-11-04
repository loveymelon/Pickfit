//
//  EmailLoginView.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import UIKit
import SnapKit
import Then

final class EmailLoginView: BaseView {

    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = true
        $0.alwaysBounceVertical = true
    }

    private let contentView = UIView()

    private let titleLabel = UILabel().then {
        $0.text = "이메일 로그인"
        $0.font = .systemFont(ofSize: 28, weight: .bold)
        $0.textColor = .black
    }

    let emailTextField = UITextField().then {
        $0.placeholder = "이메일"
        $0.borderStyle = .roundedRect
        $0.keyboardType = .emailAddress
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let passwordTextField = UITextField().then {
        $0.placeholder = "비밀번호"
        $0.borderStyle = .roundedRect
        $0.isSecureTextEntry = true
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let loginButton = UIButton(type: .system).then {
        $0.setTitle("로그인", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 12
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    }

    let signUpButton = UIButton(type: .system).then {
        $0.setTitle("회원가입", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.black.cgColor
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, emailTextField, passwordTextField, loginButton, signUpButton].forEach {
            contentView.addSubview($0)
        }
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(60)
            $0.leading.equalToSuperview().offset(24)
        }

        emailTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(40)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().offset(-24)
            $0.height.equalTo(48)
        }

        passwordTextField.snp.makeConstraints {
            $0.top.equalTo(emailTextField.snp.bottom).offset(16)
            $0.leading.trailing.height.equalTo(emailTextField)
        }

        loginButton.snp.makeConstraints {
            $0.top.equalTo(passwordTextField.snp.bottom).offset(32)
            $0.leading.trailing.equalTo(emailTextField)
            $0.height.equalTo(52)
        }

        signUpButton.snp.makeConstraints {
            $0.top.equalTo(loginButton.snp.bottom).offset(12)
            $0.leading.trailing.height.equalTo(loginButton)
            $0.bottom.equalToSuperview().offset(-40)
        }
    }

    override func configureUI() {
        backgroundColor = .white
    }
}
