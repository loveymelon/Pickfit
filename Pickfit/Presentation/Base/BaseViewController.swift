//
//  BaseViewController.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit
import RxSwift

class BaseViewController<T: BaseView>: UIViewController {

    let mainView = T()
    private let cartBarButtonView = CartBarButtonView()
    private let disposeBag = DisposeBag()

    override func loadView() {
        self.view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCartButton()
        bind()
    }

    private func setupCartButton() {
        // 장바구니 버튼을 네비게이션 우측에 추가
        let barButtonItem = UIBarButtonItem(customView: cartBarButtonView)
        navigationItem.rightBarButtonItem = barButtonItem

        // 장바구니 상태 구독하여 뱃지 업데이트
        CartManager.shared.cartItems
            .map { items in
                items.reduce(0) { $0 + $1.quantity }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] totalQuantity in
                self?.cartBarButtonView.updateBadge(count: totalQuantity)
            })
            .disposed(by: disposeBag)

        // 장바구니 버튼 탭 이벤트
        cartBarButtonView.onTap = { [weak self] in
            self?.navigateToShoppingCart()
        }
    }

    // 장바구니 버튼 숨김 (서브클래스에서 오버라이드 가능)
    func hideCartButton() {
        navigationItem.rightBarButtonItem = nil
    }

    private func navigateToShoppingCart() {
        let shoppingCartVC = ShoppingCartViewController()
        navigationController?.pushViewController(shoppingCartVC, animated: true)
    }

    func bind() {

    }

}
