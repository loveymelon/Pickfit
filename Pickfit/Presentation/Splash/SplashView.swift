//
//  SplashView.swift
//  Pickfit
//
//  Created by 김진수 on 11/11/25.
//

import UIKit
import SnapKit
import Then
import Lottie

final class SplashView: BaseView {

    // MARK: - UI Components
    let animationView = LottieAnimationView(name: "Pickfit").then {
        $0.contentMode = .scaleAspectFit
        $0.loopMode = .playOnce
        $0.backgroundBehavior = .pauseAndRestore
        $0.animationSpeed = 4.0  // 애니메이션 속도를 4배로 (원래 ~12초 → 3초)
    }

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(animationView)
    }

    override func configureLayout() {
        animationView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(300)
        }
    }

    override func configureUI() {
        super.configureUI()
        backgroundColor = .white
    }
}
