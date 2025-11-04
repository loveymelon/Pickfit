//
//  EmailLoginViewController.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

final class EmailLoginViewController: BaseViewController<EmailLoginView>, ReactorKit.View {

    var disposeBag = DisposeBag()

    init() {
        super.init(nibName: nil, bundle: nil)
        self.reactor = EmailLoginReactor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupKeyboardDismiss()
        hideCartButton()
    }

    private func setupNavigationBar() {
        title = "로그인"

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        closeButton.tintColor = .black
        navigationItem.leftBarButtonItem = closeButton
    }

    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    func bind(reactor: EmailLoginReactor) {
        // Action
        mainView.emailTextField.rx.text.orEmpty
            .map { EmailLoginReactor.Action.emailChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mainView.passwordTextField.rx.text.orEmpty
            .map { EmailLoginReactor.Action.passwordChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mainView.loginButton.rx.tap
            .map { EmailLoginReactor.Action.loginButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mainView.signUpButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigateToSignUp()
            })
            .disposed(by: disposeBag)

        // State
        reactor.state.map { $0.isFormValid }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] isValid in
                self?.mainView.loginButton.isEnabled = isValid
                self?.mainView.loginButton.alpha = isValid ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] isLoading in
                self?.mainView.loginButton.isEnabled = !isLoading
                self?.mainView.loginButton.setTitle(isLoading ? "로그인 중..." : "로그인", for: .normal)
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.isLoginSucceed }
            .distinctUntilChanged()
            .filter { $0 }
            .bind(onNext: { [weak self] _ in
                self?.handleLoginSuccess()
            })
            .disposed(by: disposeBag)

        reactor.state.compactMap { $0.errorMessage }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] errorMessage in
                self?.showAlert(title: "로그인 실패", message: errorMessage)
            })
            .disposed(by: disposeBag)
    }

    private func navigateToSignUp() {
        let signUpVC = SignUpViewController()
        let navController = UINavigationController(rootViewController: signUpVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    private func handleLoginSuccess() {
        let mainTabBar = MainTabBarController()
        mainTabBar.modalPresentationStyle = .fullScreen

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = mainTabBar
            window.makeKeyAndVisible()
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
