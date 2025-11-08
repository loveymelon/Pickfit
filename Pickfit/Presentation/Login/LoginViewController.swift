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

    private let reactor = LoginReactor()

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func bind() {
        let canLogin = reactor.state.map { !$0.isLoading }.distinctUntilChanged()

        // 이메일 로그인 버튼
        mainView.emailLoginButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.navigateToEmailLogin()
            })
            .disposed(by: disposeBag)

        // 카카오 로그인 버튼
        mainView.kakaoSignInButton.rx.tap
            .withLatestFrom(canLogin)
            .filter { $0 }
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { _ in LoginReactor.Action.kakaoLoginButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 애플 로그인 버튼
        mainView.appleSignInButton.rx.controlEvent(.touchUpInside)
            .withLatestFrom(canLogin)
            .filter { $0 }
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { _ in LoginReactor.Action.appleLoginButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 버튼 활성화 상태
        reactor.state.map { !$0.isLoading }
            .distinctUntilChanged()
            .bind(to: mainView.kakaoSignInButton.rx.isEnabled)
            .disposed(by: disposeBag)

        reactor.state.map { !$0.isLoading }
            .distinctUntilChanged()
            .bind(to: mainView.appleSignInButton.rx.isEnabled)
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

    private func navigateToEmailLogin() {
        let emailLoginVC = EmailLoginViewController()
        let navController = UINavigationController(rootViewController: emailLoginVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
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

