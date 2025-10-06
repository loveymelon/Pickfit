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

final class ImageLoadView: UIView {
    private let imageView = UIImageView().then {
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
        $0.color = .gray
    }

    private let errorView = UIView().then {
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.isHidden = true
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
    }

    private var currentImageURL: String?
    private let downsamplingSize: CGSize

    init(cornerRadius: CGFloat = 0, contentMode: UIView.ContentMode = .scaleAspectFill) {
        // 디바이스 width × height/2 크기로 다운샘플링
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        self.downsamplingSize = CGSize(width: screenWidth, height: screenHeight / 2)

        super.init(frame: .zero)

        imageView.layer.cornerRadius = cornerRadius
        imageView.contentMode = contentMode
        configureUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadImage(from urlString: String?) {
        guard let urlString = urlString else {
            showError()
            return
        }

        // 상대 경로인 경우 baseURL 추가
        let fullURLString: String
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            fullURLString = urlString
        } else {
            let baseURL = "http://pickup.sesac.kr:31668/v1"
            fullURLString = baseURL + urlString
        }

        guard let url = URL(string: fullURLString) else {
            showError()
            return
        }

        currentImageURL = urlString
        errorView.isHidden = true
        loadingIndicator.startAnimating()

        // 토큰을 먼저 가져온 후 이미지 로드
        Task {
            let accessToken = await KeychainAuthStorage.shared.readAccess()
            loadImageWithToken(url: url, accessToken: accessToken)
        }
    }

    @MainActor
    private func loadImageWithToken(url: URL, accessToken: String?) {
        let processor = DownsamplingImageProcessor(size: downsamplingSize)

        let modifier = AnyModifier { request in
            var modifiedRequest = request
            modifiedRequest.setValue(APIKey.sesacKey, forHTTPHeaderField: "SeSACKey")

            if let token = accessToken {
                modifiedRequest.setValue(token, forHTTPHeaderField: "Authorization")
            }

            return modifiedRequest
        }

        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: [
                .requestModifier(modifier),
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ],
            completionHandler: { [weak self] result in
                self?.loadingIndicator.stopAnimating()

                switch result {
                case .success:
                    self?.errorView.isHidden = true
                case .failure(let error):
                    self?.handleImageLoadError(error, url: url)
                }
            }
        )
    }

    @MainActor
    private func handleImageLoadError(_ error: KingfisherError, url: URL) {
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
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        errorImageView.snp.makeConstraints {
            $0.size.equalTo(40)
        }

        retryButton.snp.makeConstraints {
            $0.height.equalTo(32)
            $0.width.equalTo(80)
        }
    }
}
