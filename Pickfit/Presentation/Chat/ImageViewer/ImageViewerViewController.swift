//
//  ImageViewerViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/14/25.
//

import UIKit
import Kingfisher

final class ImageViewerViewController: BaseViewController<ImageViewerView> {

    private let imageURL: URL?
    private let image: UIImage?

    init(imageURL: URL) {
        self.imageURL = imageURL
        self.image = nil
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    init(image: UIImage) {
        self.imageURL = nil
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupGestures()

        if let image = image {
            displayImage(image)
        } else if let imageURL = imageURL {
            loadImage(from: imageURL)
        }
    }

    private func setupScrollView() {
        mainView.scrollView.delegate = self
    }

    private func setupGestures() {
        // 닫기 버튼
        mainView.closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        // 더블 탭으로 확대/축소
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        mainView.scrollView.addGestureRecognizer(doubleTapGesture)
    }

    private func displayImage(_ image: UIImage) {
        print("✅ [ImageViewer] Displaying direct image: \(image.size)")
        mainView.imageView.image = image
        updateImageViewConstraints(for: image.size)
    }

    private func loadImage(from url: URL) {
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

        mainView.imageView.kf.setImage(
            with: url,
            placeholder: UIImage(systemName: "photo"),
            options: [
                .requestModifier(modifier),
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        ) { [weak self] result in
            switch result {
            case .success(let value):
                print("✅ [ImageViewer] Image loaded from URL: \(value.image.size)")
                self?.updateImageViewConstraints(for: value.image.size)
            case .failure(let error):
                print("❌ [ImageViewer] Image load failed: \(error)")
            }
        }
    }

    private func updateImageViewConstraints(for imageSize: CGSize) {
        // 이미지 비율에 맞게 imageView 크기 조정
        let screenSize = view.bounds.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let screenAspectRatio = screenSize.width / screenSize.height

        mainView.imageView.snp.remakeConstraints {
            if imageAspectRatio > screenAspectRatio {
                // 가로가 긴 이미지 (화면 너비에 맞춤)
                $0.width.equalTo(mainView.scrollView.snp.width)
                $0.height.equalTo(mainView.scrollView.snp.width).multipliedBy(1.0 / imageAspectRatio)
                $0.centerX.equalToSuperview()
                $0.centerY.equalToSuperview()
            } else {
                // 세로가 긴 이미지 (화면 높이에 맞춤)
                $0.height.equalTo(mainView.scrollView.snp.height)
                $0.width.equalTo(mainView.scrollView.snp.height).multipliedBy(imageAspectRatio)
                $0.centerX.equalToSuperview()
                $0.centerY.equalToSuperview()
            }
        }

        mainView.scrollView.contentSize = mainView.imageView.frame.size
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if mainView.scrollView.zoomScale > 1.0 {
            // 축소
            mainView.scrollView.setZoomScale(1.0, animated: true)
        } else {
            // 확대
            let tapPoint = gesture.location(in: mainView.imageView)
            let zoomRect = zoomRect(for: 2.0, center: tapPoint)
            mainView.scrollView.zoom(to: zoomRect, animated: true)
        }
    }

    private func zoomRect(for scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        let scrollViewSize = mainView.scrollView.bounds.size

        zoomRect.size.width = scrollViewSize.width / scale
        zoomRect.size.height = scrollViewSize.height / scale

        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)

        return zoomRect
    }
}

// MARK: - UIScrollViewDelegate
extension ImageViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mainView.imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 줌 시 이미지를 중앙에 유지
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)

        mainView.imageView.center = CGPoint(
            x: scrollView.contentSize.width * 0.5 + offsetX,
            y: scrollView.contentSize.height * 0.5 + offsetY
        )
    }
}
