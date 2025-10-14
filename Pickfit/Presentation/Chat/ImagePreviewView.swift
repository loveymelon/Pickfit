//
//  ImagePreviewView.swift
//  Pickfit
//
//  Created by Claude on 10/14/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class ImagePreviewView: BaseView {

    // MARK: - Properties
    let disposeBag = DisposeBag()

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceHorizontal = true
    }

    private let stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
        $0.distribution = .equalSpacing
    }

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }
    }

    override func configureUI() {
        super.configureUI()
        backgroundColor = .clear
    }

    // MARK: - Public Methods

    /// 이미지 미리보기 업데이트
    /// - Parameters:
    ///   - images: 선택된 이미지 배열
    ///   - onRemove: 이미지 삭제 콜백 (index 전달)
    func updateImages(_ images: [UIImage], onRemove: @escaping (Int) -> Void) {
        print("🖼️ [ImagePreviewView] updateImages called with \(images.count) images")

        // 기존 뷰 제거
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 이미지가 없으면 숨김
        guard !images.isEmpty else {
            print("🖼️ [ImagePreviewView] No images, hiding preview")
            self.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            return
        }

        // 높이 설정 (이미지 + 여백)
        self.snp.updateConstraints { make in
            make.height.equalTo(96)
        }

        // 각 이미지 추가
        images.enumerated().forEach { index, image in
            print("🖼️ [ImagePreviewView] Adding image \(index): size=\(image.size)")
            let imageContainer = createImageContainer(image: image, index: index, onRemove: onRemove)
            stackView.addArrangedSubview(imageContainer)

            imageContainer.snp.makeConstraints {
                $0.width.height.equalTo(80)
            }
        }

        // 스택뷰 너비 설정 (이미지 개수에 따라 동적 조정)
        let totalWidth = CGFloat(images.count) * 80 + CGFloat(images.count - 1) * 8 + 16
        stackView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
            make.width.greaterThanOrEqualTo(totalWidth)
        }
    }

    // MARK: - Private Methods

    /// 이미지 컨테이너 생성 (이미지 + X 버튼)
    private func createImageContainer(image: UIImage, index: Int, onRemove: @escaping (Int) -> Void) -> UIView {
        let container = UIView().then {
            $0.backgroundColor = .systemGray6
            $0.layer.cornerRadius = 8
            $0.clipsToBounds = true
        }

        let imageView = UIImageView().then {
            $0.image = image
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }

        let removeButton = UIButton().then {
            $0.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            $0.tintColor = .white
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            $0.layer.cornerRadius = 12
            $0.clipsToBounds = true
        }

        container.addSubview(imageView)
        container.addSubview(removeButton)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        removeButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(4)
            $0.width.height.equalTo(24)
        }

        // X 버튼 탭 이벤트
        removeButton.rx.tap
            .subscribe(onNext: {
                onRemove(index)
            })
            .disposed(by: disposeBag)

        return container
    }
}
