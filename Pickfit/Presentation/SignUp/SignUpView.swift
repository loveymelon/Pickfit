//
//  SignUpView.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import UIKit
import SnapKit
import Then

final class SignUpView: BaseView {

    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = true
        $0.alwaysBounceVertical = true
    }

    private let contentView = UIView()

    private let titleLabel = UILabel().then {
        $0.text = "회원가입"
        $0.font = .systemFont(ofSize: 28, weight: .bold)
        $0.textColor = .black
    }

    // 이메일
    let emailTextField = UITextField().then {
        $0.placeholder = "이메일"
        $0.borderStyle = .roundedRect
        $0.keyboardType = .emailAddress
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let validateEmailButton = UIButton(type: .system).then {
        $0.setTitle("중복 확인", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 8
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    }

    let emailValidationLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .systemRed
        $0.numberOfLines = 0
        $0.isHidden = true
    }

    // 비밀번호
    let passwordTextField = UITextField().then {
        $0.placeholder = "비밀번호 (8자 이상, 영문/숫자/특수문자 포함)"
        $0.borderStyle = .roundedRect
        $0.isSecureTextEntry = true
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    let passwordConfirmTextField = UITextField().then {
        $0.placeholder = "비밀번호 확인"
        $0.borderStyle = .roundedRect
        $0.isSecureTextEntry = true
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    // 닉네임
    let nickTextField = UITextField().then {
        $0.placeholder = "닉네임"
        $0.borderStyle = .roundedRect
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
    }

    // 전화번호
    let phoneNumTextField = UITextField().then {
        $0.placeholder = "전화번호 (01012341234)"
        $0.borderStyle = .roundedRect
        $0.keyboardType = .phonePad
    }

    // 회원가입 버튼
    let signUpButton = UIButton(type: .system).then {
        $0.setTitle("회원가입", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 12
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

        [titleLabel, emailTextField, validateEmailButton, emailValidationLabel,
         passwordTextField, passwordConfirmTextField,
         nickTextField, phoneNumTextField, signUpButton].forEach {
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
            $0.top.equalToSuperview().offset(40)
            $0.leading.equalToSuperview().offset(24)
        }

        emailTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(32)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalTo(validateEmailButton.snp.leading).offset(-8)
            $0.height.equalTo(48)
        }

        validateEmailButton.snp.makeConstraints {
            $0.centerY.equalTo(emailTextField)
            $0.trailing.equalToSuperview().offset(-24)
            $0.width.equalTo(80)
            $0.height.equalTo(48)
        }

        emailValidationLabel.snp.makeConstraints {
            $0.top.equalTo(emailTextField.snp.bottom).offset(4)
            $0.leading.equalTo(emailTextField)
            $0.trailing.equalToSuperview().offset(-24)
        }

        passwordTextField.snp.makeConstraints {
            $0.top.equalTo(emailValidationLabel.snp.bottom).offset(16)
            $0.leading.equalTo(emailTextField)
            $0.trailing.equalTo(validateEmailButton.snp.trailing)
            $0.height.equalTo(48)
        }

        passwordConfirmTextField.snp.makeConstraints {
            $0.top.equalTo(passwordTextField.snp.bottom).offset(12)
            $0.leading.equalTo(emailTextField)
            $0.trailing.equalTo(validateEmailButton.snp.trailing)
            $0.height.equalTo(48)
        }

        nickTextField.snp.makeConstraints {
            $0.top.equalTo(passwordConfirmTextField.snp.bottom).offset(12)
            $0.leading.equalTo(emailTextField)
            $0.trailing.equalTo(validateEmailButton.snp.trailing)
            $0.height.equalTo(48)
        }

        phoneNumTextField.snp.makeConstraints {
            $0.top.equalTo(nickTextField.snp.bottom).offset(12)
            $0.leading.equalTo(emailTextField)
            $0.trailing.equalTo(validateEmailButton.snp.trailing)
            $0.height.equalTo(48)
        }

        signUpButton.snp.makeConstraints {
            $0.top.equalTo(phoneNumTextField.snp.bottom).offset(32)
            $0.leading.equalTo(emailTextField)
            $0.trailing.equalTo(validateEmailButton.snp.trailing)
            $0.height.equalTo(52)
            $0.bottom.equalToSuperview().offset(-40)
        }
    }

    override func configureUI() {
        backgroundColor = .white
    }
}
