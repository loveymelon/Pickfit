//
//  ShoppingCartViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

final class ShoppingCartViewController: BaseViewController<ShoppingCartView> {
    var disposeBag = DisposeBag()

    private let reactor = ShoppingCartReactor()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "장바구니"
        hideCartButton() // 장바구니 화면에서는 우측 상단 버튼 숨김
    }

    override func bind() {
        super.bind()

        // MARK: - Action
        rx.viewDidLoad
            .map { ShoppingCartReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 주문하기 버튼
        mainView.purchaseButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handlePurchase()
            })
            .disposed(by: disposeBag)

        // MARK: - State
        // TableView 데이터 바인딩
        reactor.state.map { $0.cartItems }
            .bind(to: mainView.tableView.rx.items(
                cellIdentifier: CartItemCell.identifier,
                cellType: CartItemCell.self
            )) { [weak self] (index: Int, item: CartItem, cell: CartItemCell) -> Void in
                self?.configureCell(cell, at: index, with: item)
            }
            .disposed(by: disposeBag)

        // 주문하기 버튼 업데이트
        reactor.state.map { $0.totalPrice }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] totalPrice in
                self?.mainView.updatePurchaseButton(totalPrice: totalPrice)
            })
            .disposed(by: disposeBag)

        // 빈 화면 처리
        reactor.state.map { $0.cartItems.isEmpty }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isEmpty in
                self?.mainView.showEmpty(isEmpty)
            })
            .disposed(by: disposeBag)
    }

    private func configureCell(_ cell: CartItemCell, at index: Int, with item: CartItem) {
        cell.configure(with: item)

        // 수량 변경
        cell.onQuantityChanged = { [weak self] newQuantity in
            self?.reactor.action.onNext(.updateQuantity(index, newQuantity))
        }

        // 삭제
        cell.onDelete = { [weak self] in
            self?.reactor.action.onNext(.deleteItem(index))
        }
    }

    private func handlePurchase() {
        let totalQuantity = reactor.currentState.totalQuantity
        let totalPrice = reactor.currentState.totalPrice

        if totalQuantity == 0 {
            showAlert(message: "장바구니가 비어있습니다")
            return
        }

        // TODO: 주문 화면으로 이동
        print("🛒 주문하기 - 총 \(totalQuantity)개, 총액: \(totalPrice)원")
        showAlert(message: "주문 기능은 준비중입니다")
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
