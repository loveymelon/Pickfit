//
//  OrderHistoryViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

final class OrderHistoryViewController: BaseViewController<OrderHistoryView> {

    private let orderReactor = OrderHistoryReactor()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()

        print("📱 [OrderHistory] viewDidLoad called")
        // 즉시 데이터 로드 트리거
        orderReactor.action.onNext(.viewDidLoad)
    }

    private func setupNavigationBar() {
//        title = "주문 현황"
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func bind() {
        bindAction()
        bindState()
    }

    private func bindAction() {
        // ViewDidLoad - 이미 viewDidLoad에서 직접 호출하므로 주석 처리
        // rx.viewDidLoad
        //     .map { OrderHistoryReactor.Action.viewDidLoad }
        //     .bind(to: orderReactor.action)
        //     .disposed(by: disposeBag)

        // Pull to Refresh
        mainView.refreshControl.rx.controlEvent(.valueChanged)
            .map { OrderHistoryReactor.Action.refresh }
            .bind(to: orderReactor.action)
            .disposed(by: disposeBag)

        // Cell Selection
        mainView.tableView.rx.itemSelected
            .withLatestFrom(orderReactor.state.map { $0.orders }) { indexPath, orders in
                orders[indexPath.row]
            }
            .subscribe(onNext: { [weak self] order in
                self?.showOrderDetail(order)
            })
            .disposed(by: disposeBag)
    }

    private func bindState() {
        // Orders
        orderReactor.state
            .map { $0.orders }
            .do(onNext: { orders in
                print("🔄 [OrderHistory VC] Orders updated: \(orders.count) items")
            })
            .distinctUntilChanged { $0.count == $1.count }
            .bind(to: mainView.tableView.rx.items(
                cellIdentifier: OrderHistoryCell.identifier,
                cellType: OrderHistoryCell.self
            )) { index, order, cell in
                print("🔄 [OrderHistory VC] Configuring cell \(index): \(order.orderCode)")
                cell.configure(with: order)
            }
            .disposed(by: disposeBag)

        // Empty State
        orderReactor.state
            .map { $0.orders.isEmpty && !$0.isLoading }
            .do(onNext: { isEmpty in
                print("🔄 [OrderHistory VC] Empty state: \(isEmpty)")
            })
            .distinctUntilChanged()
            .bind(onNext: mainView.showEmpty(_:))
            .disposed(by: disposeBag)

        // Loading (Refresh Control)
        orderReactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .bind(to: mainView.refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        // Error
        orderReactor.state
            .compactMap { $0.errorMessage }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] message in
                self?.showAlert(message: message)
            })
            .disposed(by: disposeBag)
    }

    private func showOrderDetail(_ order: OrderHistoryEntity) {
        let detailVC = OrderDetailViewController(order: order)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
