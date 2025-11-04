//
//  SignUpViewController.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

final class SignUpViewController: BaseViewController<SignUpView>, ReactorKit.View {

    var disposeBag = DisposeBag()

    init() {
        super.init(nibName: nil, bundle: nil)
        self.reactor = SignUpReactor()
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
        title = "회원가입"
        navigationController?.navigationBar.prefersLargeTitles = false

        // 닫기 버튼 추가
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        closeButton.tintColor = .black
        navigationItem.leftBarButtonItem = closeButton
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func bind(reactor: SignUpReactor) {
        // Action
        mainView.emailTextField.rx.text.orEmpty
            .map { SignUpReactor.Action.emailChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mainView.validateEmailButton.rx.tap
            .map { SignUpReactor.Action.validateEmailButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mainView.passwordTextField.rx.text.orEmpty
            .map { SignUpReactor.Action.passwordChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mainView.passwordConfirmTextField.rx.text.orEmpty
            .map { SignUpReactor.Action.passwordConfirmChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mainView.nickTextField.rx.text.orEmpty
            .map { SignUpReactor.Action.nickChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mainView.phoneNumTextField.rx.text.orEmpty
            .map { SignUpReactor.Action.phoneNumChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mainView.signUpButton.rx.tap
            .map { SignUpReactor.Action.signUpButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State
        reactor.state.map { $0.isEmailValid }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] isValid in
                self?.mainView.validateEmailButton.backgroundColor = isValid ? .systemGreen : .black
                self?.mainView.validateEmailButton.setTitle(isValid ? "✓ 확인됨" : "중복 확인", for: .normal)
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.emailValidationMessage }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] message in
                self?.mainView.emailValidationLabel.text = message
                self?.mainView.emailValidationLabel.isHidden = message == nil

                if let message = message {
                    let isValid = reactor.currentState.isEmailValid
                    self?.mainView.emailValidationLabel.textColor = isValid ? .systemGreen : .systemRed
                }
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.isFormValid }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] isValid in
                self?.mainView.signUpButton.isEnabled = isValid
                self?.mainView.signUpButton.alpha = isValid ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] isLoading in
                self?.mainView.signUpButton.isEnabled = !isLoading
                self?.mainView.signUpButton.setTitle(isLoading ? "처리 중..." : "회원가입", for: .normal)
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.isSignUpSucceed }
            .distinctUntilChanged()
            .filter { $0 }
            .bind(onNext: { [weak self] _ in
                self?.handleSignUpSuccess()
            })
            .disposed(by: disposeBag)

        reactor.state.compactMap { $0.errorMessage }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] errorMessage in
                self?.showAlert(title: "회원가입 실패", message: errorMessage)
            })
            .disposed(by: disposeBag)
    }

    private func handleSignUpSuccess() {
        let alert = UIAlertController(
            title: "회원가입 성공",
            message: "환영합니다!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            // MainTabBarController로 이동
            let mainTabBar = MainTabBarController()
            mainTabBar.modalPresentationStyle = .fullScreen

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = mainTabBar
                window.makeKeyAndVisible()
            }
        })

        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
