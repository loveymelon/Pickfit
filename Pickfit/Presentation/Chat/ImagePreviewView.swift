//
//  ImagePreviewView.swift
//  Pickfit
//
//  Created by 김진수 on 10/14/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import PDFKit

final class ImagePreviewView: BaseView {

    // MARK: - Properties
    let disposeBag = DisposeBag()

    // 파일 타입 구분을 위한 enum
    enum FilePreviewType {
        case image(UIImage)
        case pdf(Data, fileName: String)
    }

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

    // PDF 탭 콜백
    var onPDFTapped: ((Data, String) -> Void)?

    // 이미지 탭 콜백
    var onImageTapped: ((UIImage) -> Void)?

    // PDF 데이터 저장 (탭 제스처에서 사용)
    private var pdfDataMap: [Int: (data: Data, fileName: String)] = [:]

    // 이미지 데이터 저장 (탭 제스처에서 사용)
    private var imageDataMap: [Int: UIImage] = [:]

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

    /// 이미지 미리보기 업데이트 (기존 호환성 유지)
    /// - Parameters:
    ///   - images: 선택된 이미지 배열
    ///   - onRemove: 이미지 삭제 콜백 (index 전달)
    func updateImages(_ images: [UIImage], onRemove: @escaping (Int) -> Void) {
        let files = images.map { FilePreviewType.image($0) }
        updateFiles(files, onRemove: onRemove)
    }

    /// 파일 미리보기 업데이트 (이미지 + PDF 지원)
    /// - Parameters:
    ///   - files: 선택된 파일 배열 (이미지 또는 PDF)
    ///   - onRemove: 파일 삭제 콜백 (index 전달)
    func updateFiles(_ files: [FilePreviewType], onRemove: @escaping (Int) -> Void) {
        print("📄 [ImagePreviewView] updateFiles called with \(files.count) files")

        // 기존 뷰 제거
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pdfDataMap.removeAll()
        imageDataMap.removeAll()

        // 파일이 없으면 숨김
        guard !files.isEmpty else {
            print("📄 [ImagePreviewView] No files, hiding preview")
            self.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            return
        }

        // 높이 설정 (파일 + 여백)
        self.snp.updateConstraints { make in
            make.height.equalTo(96)
        }

        // 각 파일 추가
        files.enumerated().forEach { index, fileType in
            let container: UIView

            switch fileType {
            case .image(let image):
                print("🖼️ [ImagePreviewView] Adding image \(index): size=\(image.size)")
                // 이미지 데이터 저장 (탭 제스처용)
                imageDataMap[index] = image
                container = createImageContainer(image: image, index: index, onRemove: onRemove)

            case .pdf(let data, let fileName):
                print("📄 [ImagePreviewView] Adding PDF \(index): \(fileName)")
                // PDF 데이터 저장 (탭 제스처용)
                pdfDataMap[index] = (data, fileName)
                container = createPDFContainer(pdfData: data, fileName: fileName, index: index, onRemove: onRemove)
            }

            stackView.addArrangedSubview(container)

            container.snp.makeConstraints {
                $0.width.height.equalTo(80)
            }
        }

        // 스택뷰 너비 설정 (파일 개수에 따라 동적 조정)
        let totalWidth = CGFloat(files.count) * 80 + CGFloat(files.count - 1) * 8 + 16
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
                print("❌ [ImagePreviewView] Remove image at index \(index)")
                onRemove(index)
            })
            .disposed(by: disposeBag)

        // 이미지 탭 제스처 추가 (X 버튼이 아닌 이미지 영역 탭 시)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        container.tag = index

        return container
    }

    /// PDF 컨테이너 생성 (PDF 아이콘 + X 버튼)
    private func createPDFContainer(pdfData: Data, fileName: String, index: Int, onRemove: @escaping (Int) -> Void) -> UIView {
        let container = UIView().then {
            $0.backgroundColor = .systemGray6
            $0.layer.cornerRadius = 8
            $0.clipsToBounds = true
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.systemGray4.cgColor
        }

        // PDF 첫 페이지 썸네일 또는 아이콘 표시
        let contentView = UIView()

        // PDFDocument로 썸네일 생성 시도
        if let pdfDocument = PDFDocument(data: pdfData),
           let firstPage = pdfDocument.page(at: 0) {
            let pageRect = firstPage.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80))
            let thumbnail = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 80, height: 80))

                ctx.cgContext.translateBy(x: 0, y: 80)
                ctx.cgContext.scaleBy(x: 80 / pageRect.width, y: -80 / pageRect.height)
                firstPage.draw(with: .mediaBox, to: ctx.cgContext)
            }

            let thumbnailImageView = UIImageView().then {
                $0.image = thumbnail
                $0.contentMode = .scaleAspectFit
                $0.backgroundColor = .white
            }
            contentView.addSubview(thumbnailImageView)
            thumbnailImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else {
            // 썸네일 생성 실패 시 기본 아이콘 표시
            let iconImageView = UIImageView().then {
                $0.image = UIImage(systemName: "doc.fill")
                $0.tintColor = .systemRed
                $0.contentMode = .scaleAspectFit
            }
            contentView.addSubview(iconImageView)
            iconImageView.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.width.height.equalTo(40)
            }
        }

        let removeButton = UIButton().then {
            $0.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            $0.tintColor = .white
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            $0.layer.cornerRadius = 12
            $0.clipsToBounds = true
        }

        container.addSubview(contentView)
        container.addSubview(removeButton)

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        removeButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(4)
            $0.width.height.equalTo(24)
        }

        // X 버튼 탭 이벤트
        removeButton.rx.tap
            .subscribe(onNext: {
                print("📄 [ImagePreviewView] Remove PDF at index \(index)")
                onRemove(index)
            })
            .disposed(by: disposeBag)

        // PDF 탭 시 미리보기 열기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePDFTap(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        container.tag = index

        return container
    }

    @objc private func handleImageTap(_ gesture: UITapGestureRecognizer) {
        guard let container = gesture.view,
              let image = imageDataMap[container.tag] else {
            print("⚠️ [ImagePreviewView] Image data not found for tag: \(gesture.view?.tag ?? -1)")
            return
        }

        print("🖼️ [ImagePreviewView] Image tapped at index \(container.tag)")
        onImageTapped?(image)
    }

    @objc private func handlePDFTap(_ gesture: UITapGestureRecognizer) {
        guard let container = gesture.view,
              let pdfInfo = pdfDataMap[container.tag] else {
            print("⚠️ [ImagePreviewView] PDF data not found for tag: \(gesture.view?.tag ?? -1)")
            return
        }

        print("📄 [ImagePreviewView] PDF tapped: \(pdfInfo.fileName)")
        onPDFTapped?(pdfInfo.data, pdfInfo.fileName)
    }
}
