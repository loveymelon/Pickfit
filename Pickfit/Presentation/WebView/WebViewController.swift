//
//  WebViewController.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-30.
//

import UIKit
import WebKit

final class WebViewController: BaseViewController<WebView> {

    // MARK: - Properties

    private var urlString: String = ""

    // MARK: - Initialization

    convenience init(urlString: String) {
        self.init()
        self.urlString = urlString
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadWebPage()
    }

    // MARK: - Setup

    private func setupWebView() {
        mainView.webView.navigationDelegate = self

        // Add script message handlers
        let contentController = mainView.webView.configuration.userContentController
        contentController.add(self, name: "click_attendance_button")
        contentController.add(self, name: "complete_attendance")
    }

    private func loadWebPage() {
        // URL 구성: urlString이 상대 경로면 baseURL 붙이기
        let fullURLString: String
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            fullURLString = urlString  // 절대 경로
        } else {
            // 상대 경로 - baseURL과 결합 (REST API와 동일하게 /v1 포함)
            let baseURL = APIKey.baseURL
            fullURLString = baseURL + urlString
        }

        print("🌐 [WebView] Loading URL: \(fullURLString)")

        guard let url = URL(string: fullURLString) else {
            print("❌ [WebView] Invalid URL: \(fullURLString)")
            showErrorAlert(message: "잘못된 URL입니다.")
            return
        }

        var request = URLRequest(url: url)
        request.addValue(APIKey.sesacKey, forHTTPHeaderField: "SeSACKey")
        request.addValue("text/html", forHTTPHeaderField: "accept")

        print("🌐 [WebView] Headers: \(request.allHTTPHeaderFields ?? [:])")

        mainView.webView.load(request)
        mainView.startLoading()
    }

    // MARK: - JavaScript Communication

    private func sendAccessTokenToWeb() {
        Task {
            let accessToken = await KeychainAuthStorage.shared.readAccess() ?? ""

            await MainActor.run {
                let script = "requestAttendance('\(accessToken)')"
                mainView.webView.evaluateJavaScript(script) { result, error in
                    if let error = error {
                        print("❌ [WebView] JavaScript execution failed: \(error)")
                    } else {
                        print("✅ [WebView] Access token sent to web")
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "오류",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showAttendanceCompleteToast(count: Int) {
        let message = "출석 완료! 연속 \(count)일 출석 중입니다."

        let toast = UILabel().then {
            $0.text = message
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            $0.textColor = .white
            $0.textAlignment = .center
            $0.font = .systemFont(ofSize: 14, weight: .medium)
            $0.layer.cornerRadius = 8
            $0.clipsToBounds = true
            $0.numberOfLines = 0
        }

        view.addSubview(toast)

        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.leading.greaterThanOrEqualToSuperview().offset(40)
            make.trailing.lessThanOrEqualToSuperview().offset(-40)
            make.height.greaterThanOrEqualTo(40)
        }

        toast.alpha = 0

        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0) {
                toast.alpha = 0
            } completion: { _ in
                toast.removeFromSuperview()
            }
        }
    }

    // MARK: - Deinitialization

    deinit {
        mainView.webView.configuration.userContentController.removeScriptMessageHandler(forName: "click_attendance_button")
        mainView.webView.configuration.userContentController.removeScriptMessageHandler(forName: "complete_attendance")
    }
}

// MARK: - WKScriptMessageHandler

extension WebViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        print("📩 [WebView] Message received from web: \(message.name)")

        switch message.name {
        case "click_attendance_button":
            // Web requested access token for attendance
            print("🔑 [WebView] Attendance button clicked, sending access token to web")
            sendAccessTokenToWeb()

        case "complete_attendance":
            // Attendance completed, show toast
            if let body = message.body as? [String: Any],
               let count = body["count"] as? Int {
                print("✅ [WebView] Attendance completed: \(count) days")
                showAttendanceCompleteToast(count: count)
            } else {
                print("⚠️ [WebView] Invalid attendance completion data: \(message.body)")
            }

        default:
            print("⚠️ [WebView] Unknown message: \(message.name)")
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ [WebView] Page load completed")
        mainView.stopLoading()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ [WebView] Page load failed: \(error)")
        mainView.stopLoading()
        showErrorAlert(message: "페이지를 불러오는 중 오류가 발생했습니다.")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ [WebView] Provisional navigation failed: \(error)")
        mainView.stopLoading()
        showErrorAlert(message: "페이지를 불러올 수 없습니다.")
    }
}
