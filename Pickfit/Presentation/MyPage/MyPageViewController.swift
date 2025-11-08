//
//  MyPageViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/12/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

final class MyPageViewController: BaseViewController<MyPageView> {

    private let reactor = MyPageReactor()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()

        // 뷰가 로드되면 사용자 정보 조회
        reactor.action.onNext(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func bind() {
        bindAction()
        bindState()
    }

    private func bindAction() {
        // 로그아웃 버튼 탭
        mainView.logoutButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showLogoutConfirmation()
            })
            .disposed(by: disposeBag)
    }

    private func bindState() {
        // 사용자 정보 업데이트
        reactor.state
            .map { ($0.nickname, $0.email) }
            .subscribe(onNext: { [weak self] nickname, email in
                self?.mainView.configure(nickname: nickname, email: email)
            })
            .disposed(by: disposeBag)

        // 로딩 상태 (로딩 중이 아닐 때만 버튼 활성화)
        reactor.state
            .map { !$0.isLoading }
            .distinctUntilChanged()
            .bind(to: mainView.logoutButton.rx.isEnabled)
            .disposed(by: disposeBag)

        // 로그아웃 성공
        reactor.state
            .map { $0.isLogoutSuccess }
            .filter { $0 }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                print("🎉 [MyPageVC] 로그아웃 성공 감지 - 로그인 화면으로 이동")
                self?.navigateToLogin()
            })
            .disposed(by: disposeBag)

        // 에러 메시지
        reactor.state
            .compactMap { $0.errorMessage }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] message in
                self?.showAlert(message: message)
            })
            .disposed(by: disposeBag)
    }

    private func showLogoutConfirmation() {
        print("🔔 [MyPageVC] 로그아웃 확인 다이얼로그 표시")
        let alert = UIAlertController(
            title: "로그아웃",
            message: "정말 로그아웃 하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            print("❌ [MyPageVC] 로그아웃 취소")
        })
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { [weak self] _ in
            print("✅ [MyPageVC] 로그아웃 확인 - reactor action 전송")
            self?.reactor.action.onNext(.logoutButtonTapped)
        })

        present(alert, animated: true)
    }

    private func navigateToLogin() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = loginVC
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
