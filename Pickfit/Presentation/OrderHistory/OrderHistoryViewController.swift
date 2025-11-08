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
                cell.onWriteReviewTapped = { [weak self] order in
                    self?.showReviewWrite(order)
                }
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

        // 네비게이션 바 영역까지 뷰 확장
        edgesForExtendedLayout = [.top]
        extendedLayoutIncludesOpaqueBars = true

        registerCells()

        print("📱 [OrderHistory] viewDidLoad called")
        // 즉시 데이터 로드 트리거
        orderReactor.action.onNext(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
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
        // Set delegate for custom header/footer
        mainView.tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)

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

    private func showReviewWrite(_ order: OrderHistoryEntity) {
        print("✏️ [OrderHistory] Write review for order: \(order.orderCode)")

        let alert = UIAlertController(
            title: "리뷰 작성",
            message: "\(order.store.name)에 대한 리뷰를 작성하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "작성하기", style: .default) { _ in
            // TODO: Navigate to ReviewWriteViewController
            print("📝 Navigate to review write screen")
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate
extension OrderHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sections = orderReactor.currentState.sections
        guard section < sections.count else { return nil }

        let sectionModel = sections[section]

        // History 섹션만 흰색 배경 뷰 추가
        if case .history = sectionModel.model {
            let headerView = UIView()
            headerView.backgroundColor = .white

            // 상단 라운드 코너만
            headerView.layer.cornerRadius = 12
            headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

            // 섹션 타이틀 라벨
            let titleLabel = UILabel()
            titleLabel.text = "이전 주문 내역"
            titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            titleLabel.textColor = .black

            headerView.addSubview(titleLabel)

            titleLabel.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(20)
                $0.trailing.equalToSuperview().offset(-20)
                $0.top.equalToSuperview().offset(16)
                $0.bottom.equalToSuperview().offset(-8)
            }

            return headerView
        }

        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sections = orderReactor.currentState.sections
        guard section < sections.count else { return 0 }

        let sectionModel = sections[section]

        switch sectionModel.model {
        case .banner:
            return 0
        case .ongoing:
            return 40
        case .history:
            return 56  // 타이틀 공간
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
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
