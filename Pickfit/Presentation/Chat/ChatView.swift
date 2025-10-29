//
//  ChatView.swift
//  Pickfit
//
//  Created by 김진수 on 10/12/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class ChatView: BaseView {

    // MARK: - Header (상단 바)
    private let headerView = UIView().then {
        $0.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0) // ChatListView와 동일한 색상
    }

    let backButton = UIButton().then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .white
    }

    let profileImageView = UIImageView().then {
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }

    // 프로필 이미지 URL 저장 (셀에서 사용)
    private(set) var profileImageUrlString: String?

    private let nicknameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .white
    }

    let menuButton = UIButton().then {
        $0.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        $0.tintColor = .white
    }

    // MARK: - Message List
    let tableView = UITableView().then {
        $0.separatorStyle = .none
        $0.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        $0.layer.cornerRadius = 25
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.layer.masksToBounds = true
    }

    // MARK: - Input Area
    let inputContainerView = UIView().then {
        $0.backgroundColor = .white
        $0.isUserInteractionEnabled = true
    }

    let imagePreviewView = ImagePreviewView()

    let attachButton = UIButton().then {
        $0.setImage(UIImage(systemName: "paperclip"), for: .normal)
        $0.tintColor = .systemGray
    }

    let messageTextView = UITextView().then {
        $0.font = .systemFont(ofSize: 15)
        $0.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        $0.layer.cornerRadius = 18
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray5.cgColor
        $0.backgroundColor = .systemGray6
        $0.isScrollEnabled = false
        $0.showsVerticalScrollIndicator = false
        $0.isEditable = true
        $0.isSelectable = true
        $0.isUserInteractionEnabled = true
        $0.textContainer.lineFragmentPadding = 0
    }

    let sendButton = UIButton().then {
        $0.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
        $0.layer.cornerRadius = 18
        $0.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        $0.tintColor = .white
        $0.isEnabled = false
        $0.alpha = 0.5
        $0.isUserInteractionEnabled = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(tableView)
        addSubview(inputContainerView)
        inputContainerView.addSubview(imagePreviewView)
        inputContainerView.addSubview(attachButton)
        inputContainerView.addSubview(messageTextView)
        inputContainerView.addSubview(sendButton)

        // headerView를 맨 나중에 추가 (최상위 계층)
        addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(profileImageView)
        headerView.addSubview(nicknameLabel)
        headerView.addSubview(menuButton)
    }

    override func configureLayout() {
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(120)
        }

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-20)
            $0.width.height.equalTo(28)
        }

        profileImageView.snp.makeConstraints {
            $0.leading.equalTo(backButton.snp.trailing).offset(16)
            $0.centerY.equalTo(backButton)
            $0.width.height.equalTo(44)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(16)
            $0.centerY.equalTo(profileImageView)
            $0.trailing.lessThanOrEqualTo(menuButton.snp.leading).offset(-8)
        }

        menuButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(backButton)
            $0.width.height.equalTo(28)
        }

        inputContainerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.greaterThanOrEqualTo(60)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(0)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(inputContainerView.snp.top)  // inputContainer 위까지
        }

        imagePreviewView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-12)
            $0.height.equalTo(0)  // 초기에는 숨김 (이미지 선택 시 96으로 변경)
        }

        attachButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalTo(imagePreviewView.snp.bottom).offset(8)
            $0.bottom.equalToSuperview().offset(-24)
            $0.width.height.equalTo(36)
        }

        sendButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.equalTo(imagePreviewView.snp.bottom).offset(8)
            $0.bottom.equalToSuperview().offset(-24)
            $0.width.height.equalTo(36)
        }

        messageTextView.snp.makeConstraints {
            $0.leading.equalTo(attachButton.snp.trailing).offset(8)
            $0.trailing.equalTo(sendButton.snp.leading).offset(-8)
            $0.centerY.equalTo(attachButton)
            $0.height.equalTo(36).priority(.high)
        }
    }

    override func configureUI() {
        super.configureUI()
        backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0) // headerView와 같은 색상
    }

    func configure(nickname: String, profileImageUrl: String?) {
        nicknameLabel.text = nickname

        // 프로필 이미지 URL 저장 (셀에서 사용)
        self.profileImageUrlString = profileImageUrl

        // 프로필 이미지 로드
        if let profileImageUrl = profileImageUrl, !profileImageUrl.isEmpty {
            let fullURL: String
            if profileImageUrl.hasPrefix("http://") || profileImageUrl.hasPrefix("https://") {
                fullURL = profileImageUrl
            } else {
                fullURL = "http://pickup.sesac.kr:31668/v1" + profileImageUrl
            }

            Task {
                let accessToken = await KeychainAuthStorage.shared.readAccess()

                let modifier = AnyModifier { request in
                    var modifiedRequest = request
                    modifiedRequest.setValue(APIKey.sesacKey, forHTTPHeaderField: "SeSACKey")
                    if let token = accessToken {
                        modifiedRequest.setValue(token, forHTTPHeaderField: "Authorization")
                    }
                    return modifiedRequest
                }

                await MainActor.run {
                    self.profileImageView.kf.setImage(
                        with: URL(string: fullURL),
                        placeholder: UIImage(systemName: "person.circle.fill"),
                        options: [
                            .requestModifier(modifier),
                            .transition(.fade(0.2)),
                            .cacheOriginalImage
                        ]
                    )
                }
            }
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray3
        }
    }

    func updateSendButton(isEnabled: Bool) {
        sendButton.isEnabled = isEnabled
        sendButton.alpha = isEnabled ? 1.0 : 0.5
    }
}
