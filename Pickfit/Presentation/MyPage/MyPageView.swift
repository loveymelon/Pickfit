//
//  MyPageView.swift
//  Pickfit
//
//  Created by 김진수 on 10/12/25.
//

import UIKit
import SnapKit
import Then

final class MyPageView: BaseView {

    private let headerView = UIView().then {
        $0.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
    }

    private let titleLabel = UILabel().then {
        $0.text = "마이페이지"
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .white
    }

    private let profileImageView = UIImageView().then {
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 40
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }

    private let nicknameLabel = UILabel().then {
        $0.text = "사용자"
        $0.font = .systemFont(ofSize: 20, weight: .semibold)
        $0.textColor = .black
        $0.textAlignment = .center
    }

    private let emailLabel = UILabel().then {
        $0.text = ""
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .systemGray
        $0.textAlignment = .center
    }

    private let menuContainerView = UIView().then {
        $0.backgroundColor = .white
    }

    let logoutButton = UIButton().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemRed.cgColor
        $0.setTitle("로그아웃", for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)

        // 그림자 추가
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(headerView)
        headerView.addSubview(titleLabel)

        addSubview(menuContainerView)
        menuContainerView.addSubview(profileImageView)
        menuContainerView.addSubview(nicknameLabel)
        menuContainerView.addSubview(emailLabel)
        menuContainerView.addSubview(logoutButton)
    }

    override func configureLayout() {
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(120)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.bottom.equalToSuperview().offset(-20)
        }

        menuContainerView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        profileImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(40)
            $0.width.height.equalTo(80)
        }

        nicknameLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(profileImageView.snp.bottom).offset(16)
        }

        emailLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(nicknameLabel.snp.bottom).offset(4)
        }

        logoutButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(emailLabel.snp.bottom).offset(40)
            $0.leading.equalToSuperview().offset(40)
            $0.trailing.equalToSuperview().offset(-40)
            $0.height.equalTo(50)
        }
    }

    override func configureUI() {
        super.configureUI()
        backgroundColor = .white
    }

    func configure(nickname: String, email: String?) {
        nicknameLabel.text = nickname
        emailLabel.text = email ?? ""
    }
}
