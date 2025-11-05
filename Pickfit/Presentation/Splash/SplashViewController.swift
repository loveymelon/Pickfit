//
//  SplashViewController.swift
//  Pickfit
//
//  Created by 김진수 on 11/11/25.
//

import UIKit

final class SplashViewController: BaseViewController<SplashView> {

    // 애니메이션 완료 후 호출될 클로저
    var onAnimationComplete: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAnimation()
    }

    private func setupAnimation() {
        // 애니메이션 재생
        mainView.animationView.play { [weak self] finished in
            guard finished else { return }

            // 애니메이션 완료 후 0.5초 대기 후 메인 화면으로 전환
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.onAnimationComplete?()
            }
        }
    }
}
