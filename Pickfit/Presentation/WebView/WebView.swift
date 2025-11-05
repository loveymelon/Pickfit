//
//  WebView.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-30.
//

import UIKit
import WebKit
import SnapKit

final class WebView: BaseView {

    // MARK: - UI Components

    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .white
        return webView
    }()

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
        $0.color = .gray
    }

    // MARK: - UI Configuration

    override func configureHierarchy() {
        addSubview(webView)
        addSubview(loadingIndicator)
    }

    override func configureLayout() {
        webView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func configureUI() {
        backgroundColor = .white
    }

    // MARK: - Public Methods

    func startLoading() {
        loadingIndicator.startAnimating()
    }

    func stopLoading() {
        loadingIndicator.stopAnimating()
    }
}
