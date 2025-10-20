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
import RxDataSources

final class OrderHistoryViewController: BaseViewController<OrderHistoryView> {

    private let orderReactor = OrderHistoryReactor()
    private let disposeBag = DisposeBag()

    private lazy var dataSource = RxTableViewSectionedReloadDataSource<OrderHistorySectionModel>(
        configureCell: { [weak self] dataSource, tableView, indexPath, item in
            switch item {
            case .banner(let message):
                let cell = tableView.dequeueReusableCell(withIdentifier: OrderBannerCell.identifier, for: indexPath) as! OrderBannerCell
                cell.configure(with: message)
                return cell

            case .ongoingOrder(let order):
                let cell = tableView.dequeueReusableCell(withIdentifier: OrderOngoingCell.identifier, for: indexPath) as! OrderOngoingCell
                cell.configure(with: order)
                return cell

            case .historyOrder(let order):
                let cell = tableView.dequeueReusableCell(withIdentifier: OrderHistoryRowCell.identifier, for: indexPath) as! OrderHistoryRowCell
                cell.configure(with: order)
                return cell
            }
        },
        titleForHeaderInSection: { dataSource, index in
            let section = dataSource.sectionModels[index]
            switch section.model {
            case .banner:
                return nil
            case .ongoing(let title):
                return title
            case .history(let title):
                return title
            }
        }
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        registerCells()

        print("📱 [OrderHistory] viewDidLoad called")
        // 즉시 데이터 로드 트리거
        orderReactor.action.onNext(.viewDidLoad)
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
//        title = "주문 현황"
        navigationController?.navigationBar.prefersLargeTitles = false
        // 장바구니 버튼 제거
        navigationItem.rightBarButtonItem = nil
    }

    private func registerCells() {
        mainView.tableView.register(OrderBannerCell.self, forCellReuseIdentifier: OrderBannerCell.identifier)
        mainView.tableView.register(OrderOngoingCell.self, forCellReuseIdentifier: OrderOngoingCell.identifier)
        mainView.tableView.register(OrderHistoryRowCell.self, forCellReuseIdentifier: OrderHistoryRowCell.identifier)
    }

    override func bind() {
        bindAction()
        bindState()
    }

    private func bindAction() {
        // Pull to Refresh
        mainView.refreshControl.rx.controlEvent(.valueChanged)
            .map { OrderHistoryReactor.Action.refresh }
            .bind(to: orderReactor.action)
            .disposed(by: disposeBag)

        // Cell Selection
        mainView.tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                let sections = try? self.orderReactor.currentState.sections
                guard let item = sections?[indexPath.section].items[indexPath.row] else { return }

                switch item {
                case .ongoingOrder(let order), .historyOrder(let order):
                    self.showOrderDetail(order)
                case .banner:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    private func bindState() {
        // Sections
        orderReactor.state
            .map { $0.sections }
            .do(onNext: { sections in
                print("🔄 [OrderHistory VC] Sections updated: \(sections.count) sections")
            })
            .bind(to: mainView.tableView.rx.items(dataSource: dataSource))
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

//enum OrderSection {
//    case banner               // 상단 안내 배너
//    case ongoing(title: String)   // "주문현황"
//    case history(title: String)   // "이전 방문 내역"
//}
//
//enum OrderSectionItem {
//    case banner(String)                 // 배너 문구
//    case ongoingCard(OrderOngoing)      // 진행중 주문 카드(진행도 + 소항목 리스트)
//    case historyRow(OrderHistoryEntity) // 과거 주문/리뷰 행
//}
//
//struct SectionModel {
//    let model: OrderSection
//    let items: [OrderSectionItem]
//}
//
//extension SectionModel: SectionModelType {
//    init(original: SectionModel, items: [OrderSectionItem]) {
//        self = .init(model: original.model, items: items)
//    }
//}
