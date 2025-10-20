//
//  PDFViewerViewController.swift
//  Pickfit
//
//  Created by Claude on 2025-10-20.
//

import UIKit
import PDFKit
import SnapKit
import Then

final class PDFViewerViewController: UIViewController {

    private let pdfURL: URL
    private let fileName: String

    private lazy var pdfView = PDFView().then {
        $0.autoScales = true
        $0.displayMode = .singlePageContinuous
        $0.displayDirection = .vertical
    }

    private lazy var closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
    }

    private lazy var shareButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
    }

    private lazy var titleLabel = UILabel().then {
        $0.text = fileName
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    init(pdfURL: URL, fileName: String) {
        self.pdfURL = pdfURL
        self.fileName = fileName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPDF()
    }

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(pdfView)
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(shareButton)

        pdfView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(80)
            $0.trailing.lessThanOrEqualToSuperview().offset(-80)
            $0.height.equalTo(44)
        }

        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(40)
        }

        shareButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.size.equalTo(40)
        }

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }

    private func loadPDF() {
        // 원격 URL인 경우 다운로드
        if pdfURL.scheme == "http" || pdfURL.scheme == "https" {
            downloadAndDisplayPDF()
        } else {
            // 로컬 파일인 경우 바로 표시
            if let document = PDFDocument(url: pdfURL) {
                pdfView.document = document
                print("✅ [PDF Viewer] Local PDF loaded: \(fileName)")
            } else {
                showError()
            }
        }
    }

    private func downloadAndDisplayPDF() {
        print("📄 [PDF Viewer] Downloading PDF: \(pdfURL.absoluteString)")

        // 인증 헤더 추가
        var request = URLRequest(url: pdfURL)
        if let accessToken = KeychainAuthStorage.shared.readAccessSync() {
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
            print("🔑 [PDF Viewer] Added auth header")
        }
        request.setValue(APIKey.sesacKey, forHTTPHeaderField: "SeSACKey")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ [PDF Viewer] Download failed: \(error)")
                DispatchQueue.main.async {
                    self.showError()
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📄 [PDF Viewer] Response status: \(httpResponse.statusCode)")
                print("📄 [PDF Viewer] Response headers: \(httpResponse.allHeaderFields)")
            }

            guard let data = data else {
                print("❌ [PDF Viewer] No data received")
                DispatchQueue.main.async {
                    self.showError()
                }
                return
            }

            print("📄 [PDF Viewer] Downloaded \(data.count) bytes")

            // 응답 내용 디버깅
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [PDF Viewer] Response content: \(responseString)")
            }

            DispatchQueue.main.async {
                if let document = PDFDocument(data: data) {
                    self.pdfView.document = document
                    print("✅ [PDF Viewer] Remote PDF loaded: \(self.fileName)")
                } else {
                    print("❌ [PDF Viewer] Failed to create PDFDocument from data")
                    self.showError()
                }
            }
        }

        task.resume()
    }

    private func showError() {
        let alert = UIAlertController(
            title: "PDF 로드 실패",
            message: "PDF 파일을 불러올 수 없습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func shareTapped() {
        guard let document = pdfView.document else { return }

        // PDFDocument를 Data로 변환
        guard let data = document.dataRepresentation() else { return }

        // 임시 파일로 저장
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL)

            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )

            // iPad 대응
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = shareButton
                popover.sourceRect = shareButton.bounds
            }

            present(activityVC, animated: true)
        } catch {
            print("❌ [PDF Viewer] Failed to save temp file: \(error)")
        }
    }
}
