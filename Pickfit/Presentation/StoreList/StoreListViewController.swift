//
//  StoreListViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

final class StoreListViewController: BaseViewController<StoreListView> {
    var disposeBag = DisposeBag()

    private let reactor: StoreListReactor

    init(category: Category) {
        self.reactor = StoreListReactor(category: category)
        super.init(nibName: nil, bundle: nil)
        self.title = category.displayName
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let backButton = UIBarButtonItem(
            image: UIImage(named: "chevron"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
        navigationItem.hidesBackButton = true
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 탭바 숨기기
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 탭바 다시 보이기
        tabBarController?.tabBar.isHidden = false
    }

    override func bind() {
        super.bind()

        rx.viewDidLoad
            .map { StoreListReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        rx.viewIsAppearing
            .map { StoreListReactor.Action.viewIsAppearing }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.shouldNavigateToLogin }
            .filter { $0 }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.navigateToLogin()
            })
            .disposed(by: disposeBag)

        // TableView 데이터 바인딩 - 초기 로드시에만
        reactor.state.map { $0.stores }
            .filter { !$0.isEmpty }
            .take(1)
            .bind(to: mainView.tableView.rx.items(
                cellIdentifier: StoreCell.identifier,
                cellType: StoreCell.self
            )) { [weak self] index, store, cell in
                guard let reactor = self?.reactor else { return }
                cell.configure(with: store, at: index, reactor: reactor)
            }
            .disposed(by: disposeBag)

        // 좋아요 상태 변경 - 특정 셀만 업데이트
        reactor.state.map { $0.stores }
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] stores in
                guard let self = self else { return }
                stores.enumerated().forEach { index, store in
                    if let cell = self.mainView.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? StoreCell {
                        cell.updateLikeState(isPicchelin: store.isPicchelin)
                    }
                }
            })
            .disposed(by: disposeBag)

        mainView.tableView.rx
            .modelSelected(StoreEntity.self)
            .withUnretained(self)
            .subscribe(onNext: { owner, store in
                owner.navigateToStoreDetail(storeId: store.storeId)
            })
            .disposed(by: disposeBag)
    }

    private func navigateToLogin() {
        NotificationCenter.default.post(name: .navigateToLogin, object: nil)
    }

    private func navigateToStoreDetail(storeId: String) {
        let storeDetailVC = StoreDetailViewController(storeId: storeId)
        navigationController?.pushViewController(storeDetailVC, animated: true)
    }
}
