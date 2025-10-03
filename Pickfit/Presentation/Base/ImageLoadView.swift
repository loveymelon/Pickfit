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
        $0.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        $0.layer.cornerRadius = 12
        $0.isHidden = true
    }

    private let errorImageView = UIImageView().then {
        $0.image = UIImage(systemName: "exclamationmark.triangle.fill")
        $0.tintColor = .orange
        $0.contentMode = .scaleAspectFit
    }

    private let retryButton = UIButton(type: .system).then {
        $0.setTitle("재시도", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13)
        $0.backgroundColor = UIColor.systemGray6
        $0.layer.cornerRadius = 12
        $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
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
            await loadImageWithToken(url: url, accessToken: accessToken)
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
                case .failure:
                    self?.showError()
                }
            }
        )
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
        errorView.addSubview(errorImageView)
        errorView.addSubview(retryButton)
    }

    func configureLayout() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        errorView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(120)
        }

        errorImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(24)
        }

        retryButton.snp.makeConstraints {
            $0.top.equalTo(errorImageView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-12)
        }
    }
}
