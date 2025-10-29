//
//  ChatMessageCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/12/25.
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
    private var imageViews: [UIView] = []
    private var imageURLs: [String] = []

    // 이미지 탭 시 호출될 클로저
    var onImageTapped: ((URL) -> Void)?

    // PDF 탭 시 호출될 클로저
    var onPDFTapped: ((String) -> Void)?

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

    func configure(with message: ChatMessageEntity, showTime: Bool = true, showProfile: Bool = true, profileImageUrl: String? = nil) {
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

            // 프로필 이미지 로드 (헤더와 동일한 URL 사용)
            if showProfile {
                loadProfileImage(urlString: profileImageUrl)
            }
        }

        // 레이아웃 업데이트
        updateLayout()

        print("✅ [ChatMessageCell] Cell configured")
    }

    // MARK: - Image Setup

    private func setupImages(files: [String]) {
        print("🔧 [ChatMessageCell] setupImages called with \(files.count) files:")
        files.forEach { print("  - \($0)") }

        // 기존 이미지 뷰 제거
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        imageURLs = files

        guard !files.isEmpty else {
            imageContainerView.isHidden = true
            return
        }

        imageContainerView.isHidden = false

        // 파일과 이미지 분리
        let (imageFiles, pdfFiles) = separateFilesByType(files)

        print("✅ [ChatMessageCell] Separated: \(imageFiles.count) images, \(pdfFiles.count) PDFs")

        // PDF 파일이 있으면 먼저 표시
        for pdfUrl in pdfFiles {
            print("📄 [ChatMessageCell] Setting up PDF: \(pdfUrl)")
            setupPDFFile(url: pdfUrl)
        }

        // 이미지 파일 표시
        if !imageFiles.isEmpty {
            print("🖼️ [ChatMessageCell] Setting up \(imageFiles.count) images")
            // 이미지 개수별 레이아웃
            switch imageFiles.count {
            case 1:
                setupSingleImage(files: imageFiles)
            case 2:
                setupTwoImages(files: imageFiles)
            case 3:
                setupThreeImages(files: imageFiles)
            case 4:
                setupFourImages(files: imageFiles)
            case 5:
                setupFiveImages(files: imageFiles)
            default:
                break
            }
        }
    }

    private func separateFilesByType(_ files: [String]) -> (images: [String], pdfs: [String]) {
        var images: [String] = []
        var pdfs: [String] = []

        for file in files {
            let lowercased = file.lowercased()
            if lowercased.hasSuffix(".pdf") {
                pdfs.append(file)
                print("📄 [ChatMessageCell] Detected PDF: \(file)")
            } else {
                images.append(file)
                print("🖼️ [ChatMessageCell] Detected Image: \(file)")
            }
        }

        print("📊 [ChatMessageCell] Separation result: \(pdfs.count) PDFs, \(images.count) images")
        return (images, pdfs)
    }

    private func setupPDFFile(url: String) {
        let pdfView = createPDFView(url: url)
        imageContainerView.addSubview(pdfView)

        // 단일 PDF는 100x100 정사각형으로 표시 (이미지와 동일)
        pdfView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.height.equalTo(100)
        }

        imageViews.append(pdfView)
    }

    private func createPDFView(url: String) -> UIView {
        // 간단한 정사각형 컨테이너 (이미지와 동일한 크기)
        let container = UIView()
        container.backgroundColor = UIColor.systemGray6
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray4.cgColor
        container.tag = url.hashValue // URL을 tag로 저장

        // PDF 아이콘만 크게 표시
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "doc.fill")
        iconImageView.tintColor = .systemRed
        iconImageView.contentMode = .scaleAspectFit

        container.addSubview(iconImageView)

        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(50)  // 큰 아이콘
        }

        // PDF 파일 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pdfTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true

        return container
    }

    @objc private func pdfTapped(_ gesture: UITapGestureRecognizer) {
        guard let container = gesture.view else {
            print("⚠️ [ChatMessageCell] PDF tap gesture view is nil")
            return
        }

        print("🔍 [ChatMessageCell] PDF container tapped, tag: \(container.tag)")
        print("🔍 [ChatMessageCell] Available imageURLs: \(imageURLs)")

        guard let url = imageURLs.first(where: { $0.hashValue == container.tag }) else {
            print("⚠️ [ChatMessageCell] PDF URL not found for tag: \(container.tag)")
            print("⚠️ [ChatMessageCell] Available hashes: \(imageURLs.map { $0.hashValue })")
            return
        }

        print("✅ [ChatMessageCell] PDF tapped: \(url)")
        print("🔗 [ChatMessageCell] Calling onPDFTapped callback")
        onPDFTapped?(url)
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
              let index = imageViews.firstIndex(where: { ($0 as? UIImageView) == tappedImageView }),
              index < imageURLs.count else {
            print("⚠️ [ChatMessageCell] Image tap: Invalid index or not an image view")
            return
        }

        let imageURLString = imageURLs[index]

        // PDF인지 확인
        if imageURLString.lowercased().hasSuffix(".pdf") {
            print("⚠️ [ChatMessageCell] This is a PDF, not an image: \(imageURLString)")
            return
        }

        let fullURL = URL(string: APIKey.baseURL + imageURLString)

        if let url = fullURL {
            print("🖼️ [ChatMessageCell] Image tapped: \(url)")
            onImageTapped?(url)
        }
    }

    private func loadImage(into imageView: UIImageView, url: String) {
        // Kingfisher로 이미지 로드
        let fullURLString = APIKey.baseURL + url
        guard let fullURL = URL(string: fullURLString) else {
            print("❌ [ChatMessageCell] Invalid URL: \(fullURLString)")
            return
        }

        print("🖼️ [ChatMessageCell] Loading image from: \(fullURLString)")

        // Authorization 헤더 추가 (KeychainAuthStorage에서 토큰 가져오기)
        var headers: [String: String] = [
            "SeSACKey": APIKey.sesacKey
        ]

        if let accessToken = KeychainAuthStorage.shared.readAccess() {
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

        // onFailure에서 PDF 여부를 확인하고 재구성
        imageView.kf.setImage(
            with: fullURL,
            placeholder: UIImage(systemName: "photo"),
            options: [
                .requestModifier(modifier),
                .transition(.fade(0.2)),
                .cacheOriginalImage,
                .onFailureImage(UIImage(systemName: "doc.fill"))
            ]
        ) { [weak self] result in
            switch result {
            case .success(let value):
                print("✅ [ChatMessageCell] Image loaded successfully: \(value.source.url?.absoluteString ?? "unknown")")
            case .failure(let error):
                print("❌ [ChatMessageCell] Image load failed: \(error.localizedDescription)")
                print("⚠️ [ChatMessageCell] Checking if file is actually a PDF...")

                // 파일이 PDF일 가능성 확인 (서버가 .jpg로 저장해도 실제는 PDF)
                self?.checkIfPDFAndReload(url: url, fullURL: fullURL, headers: headers)
            }
        }
    }

    private func checkIfPDFAndReload(url: String, fullURL: URL, headers: [String: String]) {
        // Data를 다운로드해서 매직 넘버 확인
        var request = URLRequest(url: fullURL)
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, data.count > 4 else { return }

            // PDF 매직 넘버 확인 (%PDF)
            let header = data.prefix(4)
            if let headerString = String(data: header, encoding: .ascii), headerString == "%PDF" {
                print("✅ [ChatMessageCell] File is actually a PDF! Converting to PDF view...")

                DispatchQueue.main.async {
                    // 이미지 뷰들을 제거하고 PDF 카드로 교체
                    self.convertImageToPDFView(originalURL: url)
                }
            } else {
                print("⚠️ [ChatMessageCell] File is not a PDF, genuine image load failure")
            }
        }.resume()
    }

    private func convertImageToPDFView(originalURL: String) {
        // 기존 이미지 뷰 제거
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()

        // PDF 카드 생성 (이미지와 동일한 100x100 크기)
        let pdfView = createPDFView(url: originalURL)
        imageContainerView.addSubview(pdfView)

        pdfView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.height.equalTo(100)  // 단일 이미지와 동일한 크기
        }

        imageViews.append(pdfView)

        // 레이아웃 업데이트
        setNeedsLayout()
        layoutIfNeeded()

        print("✅ [ChatMessageCell] Converted to PDF view successfully")
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

    private func loadProfileImage(urlString: String?) {
        guard let urlString = urlString, !urlString.isEmpty else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray3
            return
        }

        let fullURL: String
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            fullURL = urlString
        } else {
            fullURL = APIKey.baseURL + urlString
        }

        guard let url = URL(string: fullURL) else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray3
            return
        }

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
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timeLabel.text = nil
        timeLabel.isHidden = false
        profileImageView.isHidden = false
        profileImageView.image = nil  // 프로필 이미지 초기화

        // 이미지 뷰 초기화
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        imageContainerView.isHidden = true
    }
}
