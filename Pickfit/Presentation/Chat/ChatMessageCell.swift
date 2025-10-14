//
//  ChatMessageCell.swift
//  Pickfit
//
//  Created by Claude on 10/12/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class ChatMessageCell: UITableViewCell {

    private let profileImageView = UIImageView().then {
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }

    private let imageContainerView = UIView().then {
        $0.backgroundColor = .clear
    }

    private let messageBubble = UIView().then {
        $0.layer.cornerRadius = 16
        $0.layer.masksToBounds = true
    }

    private let messageLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15)
        $0.numberOfLines = 0
    }

    private let timeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 11)
        $0.textColor = .systemGray
    }

    private var isMyMessage = false
    private var imageViews: [UIImageView] = []
    private var imageURLs: [String] = []

    // 이미지 탭 시 호출될 클로저
    var onImageTapped: ((URL) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(profileImageView)
        contentView.addSubview(imageContainerView)
        contentView.addSubview(messageBubble)
        messageBubble.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
    }

    func configure(with message: ChatMessageEntity, showTime: Bool = true, showProfile: Bool = true) {
        print("🔧 [ChatMessageCell] Configuring cell")
        print("  - isMyMessage: \(message.isMyMessage)")
        print("  - content: \(message.content)")
        print("  - files: \(message.files.count)")
        print("  - showTime: \(showTime)")
        print("  - showProfile: \(showProfile)")

        isMyMessage = message.isMyMessage
        messageLabel.text = message.content

        // 이미지 설정
        setupImages(files: message.files)

        // 시간 표시 여부
        if showTime {
            timeLabel.text = formatTime(message.createdAt)
            timeLabel.isHidden = false
        } else {
            timeLabel.isHidden = true
        }

        // 프로필 표시 여부 결정
        if isMyMessage {
            // 내 메시지는 항상 프로필 숨김
            profileImageView.isHidden = true
        } else {
            // 상대방 메시지는 showProfile 값에 따라
            profileImageView.isHidden = !showProfile
        }

        // 레이아웃 업데이트
        updateLayout()

        print("✅ [ChatMessageCell] Cell configured")
    }

    // MARK: - Image Setup

    private func setupImages(files: [String]) {
        // 기존 이미지 뷰 제거
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        imageURLs = files

        guard !files.isEmpty else {
            imageContainerView.isHidden = true
            return
        }

        imageContainerView.isHidden = false

        // 이미지 개수별 레이아웃
        switch files.count {
        case 1:
            setupSingleImage(files: files)
        case 2:
            setupTwoImages(files: files)
        case 3:
            setupThreeImages(files: files)
        case 4:
            setupFourImages(files: files)
        case 5:
            setupFiveImages(files: files)
        default:
            break
        }
    }

    // 1개: 100x100
    private func setupSingleImage(files: [String]) {
        let imageView = createImageView()
        imageContainerView.addSubview(imageView)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.height.equalTo(100)
        }

        loadImage(into: imageView, url: files[0])
        imageViews.append(imageView)
    }

    // 2개: 80x80 가로 나열
    private func setupTwoImages(files: [String]) {
        let imageView1 = createImageView()
        let imageView2 = createImageView()

        imageContainerView.addSubview(imageView1)
        imageContainerView.addSubview(imageView2)

        imageView1.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.height.equalTo(80)
        }

        imageView2.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(imageView1.snp.trailing).offset(4)
            $0.width.height.equalTo(80)
        }

        loadImage(into: imageView1, url: files[0])
        loadImage(into: imageView2, url: files[1])
        imageViews.append(contentsOf: [imageView1, imageView2])
    }

    // 3개: 2개(상단) + 1개(하단)
    private func setupThreeImages(files: [String]) {
        let imageView1 = createImageView()
        let imageView2 = createImageView()
        let imageView3 = createImageView()

        imageContainerView.addSubview(imageView1)
        imageContainerView.addSubview(imageView2)
        imageContainerView.addSubview(imageView3)

        imageView1.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.width.height.equalTo(80)
        }

        imageView2.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
            $0.leading.equalTo(imageView1.snp.trailing).offset(4)
            $0.width.height.equalTo(80)
        }

        imageView3.snp.makeConstraints {
            $0.top.equalTo(imageView1.snp.bottom).offset(4)
            $0.leading.bottom.equalToSuperview()
            $0.width.height.equalTo(80)
        }

        loadImage(into: imageView1, url: files[0])
        loadImage(into: imageView2, url: files[1])
        loadImage(into: imageView3, url: files[2])
        imageViews.append(contentsOf: [imageView1, imageView2, imageView3])
    }

    // 4개: 2x2 그리드
    private func setupFourImages(files: [String]) {
        let imageView1 = createImageView()
        let imageView2 = createImageView()
        let imageView3 = createImageView()
        let imageView4 = createImageView()

        imageContainerView.addSubview(imageView1)
        imageContainerView.addSubview(imageView2)
        imageContainerView.addSubview(imageView3)
        imageContainerView.addSubview(imageView4)

        // 상단 2개
        imageView1.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.width.height.equalTo(80)
        }

        imageView2.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
            $0.leading.equalTo(imageView1.snp.trailing).offset(4)
            $0.width.height.equalTo(80)
        }

        // 하단 2개
        imageView3.snp.makeConstraints {
            $0.top.equalTo(imageView1.snp.bottom).offset(4)
            $0.leading.bottom.equalToSuperview()
            $0.width.height.equalTo(80)
        }

        imageView4.snp.makeConstraints {
            $0.top.equalTo(imageView2.snp.bottom).offset(4)
            $0.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(imageView3.snp.trailing).offset(4)
            $0.width.height.equalTo(80)
        }

        loadImage(into: imageView1, url: files[0])
        loadImage(into: imageView2, url: files[1])
        loadImage(into: imageView3, url: files[2])
        loadImage(into: imageView4, url: files[3])
        imageViews.append(contentsOf: [imageView1, imageView2, imageView3, imageView4])
    }

    // 5개: 3개(상단, 55x55) + 2개(하단, 90x70)
    private func setupFiveImages(files: [String]) {
        let imageView1 = createImageView()
        let imageView2 = createImageView()
        let imageView3 = createImageView()
        let imageView4 = createImageView()
        let imageView5 = createImageView()

        imageContainerView.addSubview(imageView1)
        imageContainerView.addSubview(imageView2)
        imageContainerView.addSubview(imageView3)
        imageContainerView.addSubview(imageView4)
        imageContainerView.addSubview(imageView5)

        // 상단 3개 (55x55)
        imageView1.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.width.height.equalTo(55)
        }

        imageView2.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalTo(imageView1.snp.trailing).offset(4)
            $0.width.height.equalTo(55)
        }

        imageView3.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
            $0.leading.equalTo(imageView2.snp.trailing).offset(4)
            $0.width.height.equalTo(55)
        }

        // 하단 2개 (90x70)
        imageView4.snp.makeConstraints {
            $0.top.equalTo(imageView1.snp.bottom).offset(4)
            $0.leading.bottom.equalToSuperview()
            $0.width.equalTo(90)
            $0.height.equalTo(70)
        }

        imageView5.snp.makeConstraints {
            $0.top.equalTo(imageView3.snp.bottom).offset(4)
            $0.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(imageView4.snp.trailing).offset(4)
            $0.width.equalTo(90)
            $0.height.equalTo(70)
        }

        loadImage(into: imageView1, url: files[0])
        loadImage(into: imageView2, url: files[1])
        loadImage(into: imageView3, url: files[2])
        loadImage(into: imageView4, url: files[3])
        loadImage(into: imageView5, url: files[4])
        imageViews.append(contentsOf: [imageView1, imageView2, imageView3, imageView4, imageView5])
    }

    private func createImageView() -> UIImageView {
        let imageView = UIImageView().then {
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
            $0.backgroundColor = .systemGray6
            $0.layer.cornerRadius = 8
            $0.isUserInteractionEnabled = true
        }

        // 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        imageView.addGestureRecognizer(tapGesture)

        return imageView
    }

    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedImageView = gesture.view as? UIImageView,
              let index = imageViews.firstIndex(of: tappedImageView),
              index < imageURLs.count else {
            return
        }

        let imageURLString = imageURLs[index]
        let fullURL = URL(string: APIKey.baseURL + imageURLString)

        if let url = fullURL {
            print("🖼️ [ChatMessageCell] Image tapped: \(url)")
            onImageTapped?(url)
        }
    }

    private func loadImage(into imageView: UIImageView, url: String) {
        // Kingfisher로 이미지 로드
        let fullURLString = APIKey.baseURL + url
        let fullURL = URL(string: fullURLString)

        print("🖼️ [ChatMessageCell] Loading image from: \(fullURLString)")
        print("🖼️ [ChatMessageCell] URL valid: \(fullURL != nil)")

        // Authorization 헤더 추가 (KeychainAuthStorage에서 토큰 가져오기)
        var headers: [String: String] = [
            "SeSACKey": APIKey.sesacKey
        ]

        if let accessToken = KeychainAuthStorage.shared.readAccessSync() {
            headers["Authorization"] = accessToken
        }

        // KingfisherOptionsInfo로 헤더 추가
        let modifier = AnyModifier { request in
            var modifiedRequest = request
            headers.forEach { key, value in
                modifiedRequest.setValue(value, forHTTPHeaderField: key)
            }
            return modifiedRequest
        }

        imageView.kf.setImage(
            with: fullURL,
            placeholder: UIImage(systemName: "photo"),
            options: [
                .requestModifier(modifier),
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        ) { result in
            switch result {
            case .success(let value):
                print("✅ [ChatMessageCell] Image loaded successfully: \(value.source.url?.absoluteString ?? "unknown")")
            case .failure(let error):
                print("❌ [ChatMessageCell] Image load failed: \(error.localizedDescription)")
                print("❌ [ChatMessageCell] URL was: \(fullURLString)")
            }
        }
    }

    private func updateLayout() {
        // 기존 constraints 제거
        profileImageView.snp.removeConstraints()
        imageContainerView.snp.removeConstraints()
        messageBubble.snp.removeConstraints()
        messageLabel.snp.removeConstraints()
        timeLabel.snp.removeConstraints()

        let hasImages = !imageContainerView.isHidden

        if isMyMessage {
            // 내 메시지 (오른쪽 정렬, 핑크색)
            profileImageView.isHidden = true
            messageBubble.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
            messageLabel.textColor = .white

            if hasImages {
                // 이미지가 있으면 상단에 배치
                imageContainerView.snp.makeConstraints {
                    $0.top.equalToSuperview().offset(4)
                    $0.trailing.equalToSuperview().offset(-16)
                }

                messageBubble.snp.makeConstraints {
                    $0.top.equalTo(imageContainerView.snp.bottom).offset(4)
                    $0.trailing.equalToSuperview().offset(-16)
                    $0.bottom.equalToSuperview().offset(-4)
                    $0.width.lessThanOrEqualTo(250)
                }
            } else {
                messageBubble.snp.makeConstraints {
                    $0.top.equalToSuperview().offset(4)
                    $0.trailing.equalToSuperview().offset(-16)
                    $0.bottom.equalToSuperview().offset(-4)
                    $0.width.lessThanOrEqualTo(250)
                }
            }

            messageLabel.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))
            }

            timeLabel.snp.makeConstraints {
                $0.trailing.equalTo(hasImages ? imageContainerView.snp.leading : messageBubble.snp.leading).offset(-6)
                $0.bottom.equalTo(messageBubble)
                $0.height.equalTo(12)
            }

        } else {
            // 상대방 메시지 (왼쪽 정렬, 회색)
            messageBubble.backgroundColor = .systemGray6
            messageLabel.textColor = .black

            if profileImageView.isHidden {
                // 프로필 숨김 → imageContainer/messageBubble을 왼쪽에 배치 (프로필 영역만큼 들여쓰기)
                if hasImages {
                    imageContainerView.snp.makeConstraints {
                        $0.top.equalToSuperview().offset(4)
                        $0.leading.equalToSuperview().offset(16 + 32 + 8)
                    }

                    messageBubble.snp.makeConstraints {
                        $0.top.equalTo(imageContainerView.snp.bottom).offset(4)
                        $0.leading.equalToSuperview().offset(16 + 32 + 8)
                        $0.bottom.equalToSuperview().offset(-4)
                        $0.width.lessThanOrEqualTo(250)
                    }
                } else {
                    messageBubble.snp.makeConstraints {
                        $0.top.equalToSuperview().offset(4)
                        $0.leading.equalToSuperview().offset(16 + 32 + 8)  // leading + 프로필 크기 + spacing
                        $0.bottom.equalToSuperview().offset(-4)
                        $0.width.lessThanOrEqualTo(250)
                    }
                }
            } else {
                // 프로필 표시 → 정상 레이아웃
                profileImageView.snp.makeConstraints {
                    $0.leading.equalToSuperview().offset(16)
                    $0.top.equalToSuperview().offset(4)
                    $0.width.height.equalTo(32)
                }

                if hasImages {
                    imageContainerView.snp.makeConstraints {
                        $0.top.equalToSuperview().offset(4)
                        $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
                    }

                    messageBubble.snp.makeConstraints {
                        $0.top.equalTo(imageContainerView.snp.bottom).offset(4)
                        $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
                        $0.bottom.equalToSuperview().offset(-4)
                        $0.width.lessThanOrEqualTo(250)
                    }
                } else {
                    messageBubble.snp.makeConstraints {
                        $0.top.equalToSuperview().offset(4)
                        $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
                        $0.bottom.equalToSuperview().offset(-4)
                        $0.width.lessThanOrEqualTo(250)
                    }
                }
            }

            messageLabel.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))
            }

            timeLabel.snp.makeConstraints {
                $0.leading.equalTo(messageBubble.snp.trailing).offset(6)
                $0.bottom.equalTo(messageBubble)
                $0.height.equalTo(12)
            }
        }
    }

    private func formatTime(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: dateString) else {
            print("❌ [formatTime] Failed to parse date: \(dateString)")
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        let result = formatter.string(from: date)
        print("✅ [formatTime] \(dateString) → \(result)")
        return result
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timeLabel.text = nil
        timeLabel.isHidden = false
        profileImageView.isHidden = false  // 재사용 시 프로필 초기화

        // 이미지 뷰 초기화
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        imageContainerView.isHidden = true
    }
}
