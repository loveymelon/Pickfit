//
//  ImageLoadView.swift
//  Pickfit
//
//  Created by 김진수 on 10/3/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

// MARK: - 캐싱 전략 정의

/// 이미지 캐싱 전략 (뷰 특성에 따른 최적화)
enum ImageCachingStrategy {
    /// 디스크 + 메모리 캐싱 (기본값)
    /// - 사용처: 상품 이미지, 프로필 이미지 등 재사용 빈도 높은 이미지
    /// - 장점: 빠른 재로드, 데이터 절약
    /// - 단점: 디스크 용량 사용
    case diskAndMemory

    /// 메모리 캐싱만 사용
    /// - 사용처: 채팅 이미지, 일회성 콘텐츠
    /// - 장점: 디스크 용량 절약, 캐시 관리 용이
    /// - 단점: 앱 재시작 시 재다운로드
    case memoryOnly

    /// 캐싱 사용 안 함
    /// - 사용처: 실시간 데이터 (QR 코드, 일회용 쿠폰 등)
    /// - 장점: 항상 최신 상태 보장
    /// - 단점: 매번 다운로드 (느림, 데이터 소모)
    case none
}

final class ImageLoadView: UIView {
    private let imageView = UIImageView().then {
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
    }

    // 외부에서 직접 이미지 설정 가능하도록 노출
    var image: UIImage? {
        get { imageView.image }
        set {
            imageView.image = newValue
            // 이미지 설정 시 로딩/에러 뷰 숨김
            loadingIndicator.stopAnimating()
            errorView.isHidden = true
        }
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
        $0.color = .gray
    }

    private let errorView = UIView().then {
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.isHidden = true
        $0.isUserInteractionEnabled = true
    }

    private let errorStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 8
    }

    private let errorImageView = UIImageView().then {
        $0.image = UIImage(systemName: "photo")
        $0.tintColor = .systemGray3
        $0.contentMode = .scaleAspectFit
    }

    private let errorLabel = UILabel().then {
        $0.text = "이미지를 불러올 수 없습니다"
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .systemGray
        $0.textAlignment = .center
    }

    private let retryButton = UIButton(type: .system).then {
        $0.setTitle("재시도", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        $0.backgroundColor = .white
        $0.setTitleColor(.systemBlue, for: .normal)
        $0.layer.cornerRadius = 6
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
        $0.isUserInteractionEnabled = true
    }

    private var currentImageURL: String?
    private let downsamplingSize: CGSize
    private let cachingStrategy: ImageCachingStrategy

    init(
        cornerRadius: CGFloat = 0,
        contentMode: UIView.ContentMode = .scaleAspectFill,
        cachingStrategy: ImageCachingStrategy = .diskAndMemory
    ) {
        // 디바이스 width × height/2 크기로 다운샘플링
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        self.downsamplingSize = CGSize(width: screenWidth, height: screenHeight / 2)
        self.cachingStrategy = cachingStrategy

        super.init(frame: .zero)

        imageView.layer.cornerRadius = cornerRadius
        imageView.contentMode = contentMode

        // ImageLoadView 자체에도 cornerRadius 적용 (배경색이 보일 때를 대비)
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true

        configureUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadImage(from urlString: String?) {
        print("🖼️ [ImageLoadView] loadImage 호출")
        print("   - urlString: \(urlString ?? "nil")")

        guard let urlString = urlString else {
            print("   ❌ urlString is nil")
            showError()
            return
        }

        // 같은 URL이면 중복 로드 방지
        if currentImageURL == urlString, imageView.image != nil {
            print("   ⏭️ 중복 로드 방지 (이미 로드됨)")
            return
        }

        // 이전 로딩 취소
        imageView.kf.cancelDownloadTask()

        // 상대 경로인 경우 baseURL 추가
        let fullURLString: String
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            fullURLString = urlString
            print("   🌐 절대 URL: \(fullURLString)")
        } else {
            let baseURL = "http://pickup.sesac.kr:31668/v1"
            fullURLString = baseURL + urlString
            print("   🔗 상대 → 절대 변환: \(fullURLString)")
        }

        guard let url = URL(string: fullURLString) else {
            print("   ❌ Invalid URL: \(fullURLString)")
            showError()
            return
        }

        currentImageURL = urlString
        errorView.isHidden = true
        loadingIndicator.startAnimating()

        print("   🔄 로딩 시작...")

        // 토큰을 먼저 가져온 후 이미지 로드
        Task {
            let accessToken = await KeychainAuthStorage.shared.readAccess()
            print("   🔐 Token 가져옴: \(accessToken != nil ? "있음" : "없음")")
            loadImageWithToken(url: url, accessToken: accessToken)
        }
    }

    /// 동영상 URL에서 썸네일 생성 후 표시
    func loadVideoThumbnail(from urlString: String?) {
        print("🎬 [ImageLoadView] loadVideoThumbnail 호출됨")
        print("   - urlString: \(urlString ?? "nil")")

        guard let urlString = urlString else {
            print("   ❌ urlString is nil")
            showError()
            return
        }

        // 같은 URL이면 중복 로드 방지
        if currentImageURL == urlString, imageView.image != nil {
            print("   ⏭️ 중복 로드 방지 (이미 로드됨)")
            return
        }

        // 이전 로딩 취소
        imageView.kf.cancelDownloadTask()

        // 상대 경로인 경우 baseURL 추가
        let fullURLString: String
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            fullURLString = urlString
            print("   🌐 절대 URL: \(fullURLString)")
        } else {
            let baseURL = "http://pickup.sesac.kr:31668/v1"
            fullURLString = baseURL + urlString
            print("   🔗 상대 → 절대 변환: \(fullURLString)")
        }

        guard let url = URL(string: fullURLString) else {
            print("   ❌ Invalid URL: \(fullURLString)")
            showError()
            return
        }

        currentImageURL = urlString
        errorView.isHidden = true
        loadingIndicator.startAnimating()
        print("   🔄 로딩 인디케이터 시작")

        // 썸네일 생성 (백그라운드)
        Task {
            do {
                // 토큰 가져오기
                let accessToken = await KeychainAuthStorage.shared.readAccess()
                print("   🔐 Token 가져옴: \(accessToken != nil ? "있음" : "없음")")

                print("🎬 [ImageLoadView] Generating video thumbnail for: \(url.lastPathComponent)")
                let thumbnail = try await VideoThumbnailGenerator.shared.generateQuickThumbnail(from: url, accessToken: accessToken)
                print("   ✅ 썸네일 생성 완료: \(thumbnail.size)")

                await MainActor.run {
                    print("   🎨 UI 업데이트 시작")
                    self.imageView.image = thumbnail
                    self.imageView.contentMode = .scaleAspectFill
                    self.loadingIndicator.stopAnimating()
                    self.errorView.isHidden = true
                    print("✅ [ImageLoadView] Video thumbnail loaded successfully")

                    // Kingfisher 캐시에 저장 (다음에 재사용)
                    ImageCache.default.store(thumbnail, forKey: fullURLString)
                }
            } catch {
                print("❌ [ImageLoadView] Failed to generate video thumbnail: \(error.localizedDescription)")
                print("   - Error: \(error)")
                await MainActor.run {
                    self.showError()
                }
            }
        }
    }

    @MainActor
    private func loadImageWithToken(url: URL, accessToken: String?, retryWithoutDownsampling: Bool = false) {
        print("   📥 [ImageLoadView] Kingfisher 로드 시작")
        print("      - URL: \(url)")
        print("      - downsampling: \(!retryWithoutDownsampling)")

        let modifier = AnyModifier { request in
            var modifiedRequest = request
            modifiedRequest.setValue(APIKey.sesacKey, forHTTPHeaderField: "SeSACKey")

            if let token = accessToken {
                modifiedRequest.setValue(token, forHTTPHeaderField: "Authorization")
            }

            return modifiedRequest
        }

        var options: KingfisherOptionsInfo = [
            .requestModifier(modifier),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.2))
        ]

        // 캐싱 전략 적용
        switch cachingStrategy {
        case .diskAndMemory:
            // 디스크 + 메모리 캐싱 (기본값)
            options.append(.cacheOriginalImage)  // 원본 이미지도 디스크에 캐시

        case .memoryOnly:
            // 메모리 캐싱만 사용 (디스크 캐시 제외)
            options.append(.cacheMemoryOnly)

        case .none:
            // 캐싱 사용 안 함
            options.append(.forceRefresh)  // 항상 새로 다운로드
        }

        // 다운샘플링 실패 시에는 원본 이미지 사용
        if !retryWithoutDownsampling {
            let processor = DownsamplingImageProcessor(size: downsamplingSize)
            options.append(.processor(processor))
        }

        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: options,
            completionHandler: { [weak self] result in
                self?.loadingIndicator.stopAnimating()

                switch result {
                case .success(let value):
                    print("      ✅ [ImageLoadView] 이미지 로드 성공!")
                    print("         - size: \(value.image.size)")
                    print("         - source: \(value.cacheType)")
                    self?.errorView.isHidden = true

                case .failure(let error):
                    print("      ❌ [ImageLoadView] 이미지 로드 실패: \(error.localizedDescription)")

                    // 프로세서 에러 처리
                    if case .processorError = error {
                        if !retryWithoutDownsampling {
                            print("      ⚠️ [Image] Downsampling failed, retrying with original image")
                            self?.loadImageWithToken(url: url, accessToken: accessToken, retryWithoutDownsampling: true)
                        } else {
                            print("      ❌ [Image] Original image processing also failed")
                            // 이미지 처리 불가능 - 에러 표시하지 않고 플레이스홀더만 표시
                            self?.errorView.isHidden = true
                            self?.imageView.image = UIImage(systemName: "photo")
                            self?.imageView.tintColor = .systemGray3
                            self?.imageView.contentMode = .scaleAspectFit
                        }
                    } else {
                        self?.handleImageLoadError(error, url: url)
                    }
                }
            }
        )
    }

    @MainActor
    private func handleImageLoadError(_ error: KingfisherError, url: URL) {
        // Source mismatch 에러는 무시 (이미지는 성공적으로 로드됨)
        let errorDescription = error.localizedDescription
        if errorDescription.contains("not the one currently expected") {
            print("ℹ️ [Image] Source mismatch ignored (image loaded successfully)")
            return
        }

        // 419 에러인지 확인 (토큰 만료)
        if case .responseError(let reason) = error,
           case .invalidHTTPStatusCode(let response) = reason,
           response.statusCode == 419 {
            print("❌ [Image] 419 - Token expired for image: \(url.lastPathComponent)")
            // 토큰 갱신 후 재시도
            Task {
                do {
                    print("🔄 [Image] Starting token refresh for image...")
                    _ = try await TokenRefreshCoordinator.shared.refresh {
                        try await self.refreshToken()
                    }
                    print("✅ [Image] Token refresh successful - Retrying image load")
                    // 토큰 갱신 성공 - 이미지 다시 로드
                    self.loadImage(from: self.currentImageURL)
                } catch {
                    print("❌ [Image] Token refresh failed: \(error.localizedDescription)")
                    // 토큰 갱신 실패 - 에러 표시
                    self.showError()
                }
            }
        } else {
            print("❌ [Image] Load failed: \(error.localizedDescription)")
            // 다른 에러 - 에러 표시
            self.showError()
        }
    }

    private func refreshToken() async throws -> String {
        guard let refreshToken = await KeychainAuthStorage.shared.readRefresh(),
              let accessToken = await KeychainAuthStorage.shared.readAccess() else {
            throw NSError(domain: "ImageLoadView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token이 없습니다"])
        }

        let dto = try await NetworkManager.auth.fetch(
            dto: RefreshTokenResponseDTO.self,
            router: LoginRouter.refreshToken(RefreshTokenRequestDTO(
                accessToken: accessToken,
                refreshToken: refreshToken
            ))
        )

        // 새 토큰 저장
        await KeychainAuthStorage.shared.write(access: dto.accessToken, refresh: dto.refreshToken)

        return dto.accessToken
    }

    func cancelLoading() {
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        errorView.isHidden = true
        loadingIndicator.stopAnimating()
        currentImageURL = nil
    }

    private func setupActions() {
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)

        // errorView에 탭 제스처 추가 (셀 선택 이벤트 차단)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(errorViewTapped))
        errorView.addGestureRecognizer(tapGesture)
    }

    @objc private func errorViewTapped() {
        // errorView가 탭되면 아무것도 하지 않음 (셀 선택 차단)
    }

    @objc private func retryButtonTapped() {
        guard let imageUrl = currentImageURL else { return }
        errorView.isHidden = true
        loadImage(from: imageUrl)
    }

    private func showError() {
        loadingIndicator.stopAnimating()
        errorView.isHidden = false
    }
}

extension ImageLoadView: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
    }

    func configureHierarchy() {
        addSubview(imageView)
        addSubview(loadingIndicator)
        addSubview(errorView)
        errorView.addSubview(errorStackView)
        errorStackView.addArrangedSubview(errorImageView)
        errorStackView.addArrangedSubview(errorLabel)
        errorStackView.addArrangedSubview(retryButton)
    }

    func configureLayout() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        errorView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        errorStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(8)
            $0.trailing.lessThanOrEqualToSuperview().offset(-8)
        }

        errorImageView.snp.makeConstraints {
            $0.size.equalTo(40).priority(.high)
        }

        retryButton.snp.makeConstraints {
            $0.height.equalTo(32).priority(.high)
            $0.width.equalTo(80).priority(.high)
        }
    }
}
