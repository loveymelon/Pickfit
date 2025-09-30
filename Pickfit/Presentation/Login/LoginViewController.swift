//
//  LoginViewController.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

final class LoginViewController: BaseViewController<LoginView> {

    var disposeBag = DisposeBag()

    private let reactor: LoginReactor

    init(authRepository: AuthRepository) {
        self.reactor = LoginReactor(authRepository: authRepository)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func bind() {
        let canLogin = reactor.state.map { !$0.isLoading }.distinctUntilChanged()
        
        mainView.signInButton.rx.tap
            .withLatestFrom(canLogin)
            .filter { $0 }
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { _ in LoginReactor.Action.loginButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { !$0.isLoading }
            .distinctUntilChanged()
            .bind(to: mainView.signInButton.rx.isEnabled)
            .disposed(by: disposeBag)

        reactor.state.compactMap { $0.errorMessage }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] errorMessage in
                self?.showAlert(message: errorMessage)
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.isLoginSucceed }
            .filter { $0 }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.navigateToHome()
            })
            .disposed(by: disposeBag)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "로그인 오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func navigateToHome() {
        let tabBarController = MainTabBarController()
        tabBarController.modalPresentationStyle = .fullScreen

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
}

