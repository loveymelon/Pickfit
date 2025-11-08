//
//  InAppNotificationView.swift
//  Pickfit
//
//  Created by 김진수 on 10/19/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

/// 앱 실행 중 다른 화면에서 메시지를 받았을 때 표시되는 In-App 배너
/// - 화면 상단에서 스르륵 내려옴
/// - 프로필 이미지 + 닉네임 + 메시지 미리보기
/// - 탭하면 해당 채팅방으로 이동
/// - 3초 후 자동으로 사라짐
final class InAppNotificationView: UIView {

    // MARK: - UI Components

    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowOffset = CGSize(width: 0, height: 4)
        $0.layer.shadowRadius = 8
    }

    private let profileImageView = UIImageView().then {
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }

    private let nicknameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .black
    }

    private let messageLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13)
        $0.textColor = .darkGray
        $0.numberOfLines = 2
    }

    private let appNameLabel = UILabel().then {
        $0.text = "Pickfit"
        $0.font = .systemFont(ofSize: 11, weight: .medium)
        $0.textColor = .systemGray
    }

    // MARK: - Properties

    private var onTap: (() -> Void)?
    private var hideTimer: Timer?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(appNameLabel)
        containerView.addSubview(profileImageView)
        containerView.addSubview(nicknameLabel)
        containerView.addSubview(messageLabel)

        // 레이아웃
        containerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(80)
        }

        appNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(12)
        }

        profileImageView.snp.makeConstraints {
            $0.top.equalTo(appNameLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(12)
            $0.width.height.equalTo(40)
        }

        nicknameLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-12)
        }

        messageLabel.snp.makeConstraints {
            $0.top.equalTo(nicknameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-12)
        }

        // 탭 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
    }

    // MARK: - Public Methods

    /// 배너를 표시합니다
    /// - Parameters:
    ///   - nickname: 메시지를 보낸 사용자 닉네임
    ///   - message: 메시지 내용 (미리보기)
    ///   - profileImage: 프로필 이미지 URL
    ///   - onTap: 배너를 탭했을 때 실행될 클로저
    func show(
        nickname: String,
        message: String,
        profileImage: String?,
        onTap: @escaping () -> Void
    ) {
        print("🔔 [InAppNotificationView] Showing banner for \(nickname)")

        self.onTap = onTap

        // 데이터 설정
        nicknameLabel.text = nickname
        messageLabel.text = message

        // 프로필 이미지 로드
        if let profileImageURL = profileImage, !profileImageURL.isEmpty {
            let fullURLString = APIKey.baseURL + profileImageURL
            let url = URL(string: fullURLString)

            // Authorization 헤더 추가 (ChatMessageCell과 동일한 방식)
            var headers: [String: String] = [
                "SeSACKey": APIKey.sesacKey
            ]

            if let accessToken = KeychainAuthStorage.shared.readAccess() {
                headers["Authorization"] = accessToken
            }

            let modifier = AnyModifier { request in
                var modifiedRequest = request
                headers.forEach { key, value in
                    modifiedRequest.setValue(value, forHTTPHeaderField: key)
                }
                return modifiedRequest
            }

            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [
                    .requestModifier(modifier),
                    .transition(.fade(0.2))
                ]
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }

        // 애니메이션으로 등장
        animateIn()

        // 3초 후 자동으로 사라짐
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    /// 배너를 즉시 숨깁니다
    func hide() {
        print("🔔 [InAppNotificationView] Hiding banner")
        hideTimer?.invalidate()
        animateOut()
    }

    // MARK: - Animations

    /// 위에서 스르륵 내려오는 애니메이션
    private func animateIn() {
        // 초기 위치: 화면 위쪽 밖
        self.containerView.transform = CGAffineTransform(translationX: 0, y: -100)
        self.alpha = 0

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.containerView.transform = .identity
            self.alpha = 1
        }
    }

    /// 위로 스르륵 올라가며 사라지는 애니메이션
    private func animateOut() {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseIn
        ) {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: -100)
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        print("🔔 [InAppNotificationView] Banner tapped")
        hide()
        onTap?()
    }

    deinit {
        hideTimer?.invalidate()
        print("🔔 [InAppNotificationView] Deallocated")
    }
}
