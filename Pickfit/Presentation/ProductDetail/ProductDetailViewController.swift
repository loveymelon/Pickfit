//
//  ProductDetailViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/6/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

final class ProductDetailViewController: BaseViewController<ProductDetailView> {
    var disposeBag = DisposeBag()

    private let reactor: ProductDetailReactor

    init(menus: [StoreDetailEntity.Menu]) {
        self.reactor = ProductDetailReactor(menus: menus)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "상품 상세"

    }

    override func bind() {
        super.bind()

        rx.viewDidLoad
            .map { ProductDetailReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // imageUrls를 CollectionView에 바인딩
        reactor.state.map { $0.imageUrls }
            .distinctUntilChanged()
            .bind(to: mainView.collectionView.rx.items(
                cellIdentifier: StoreDetailCell.identifier,
                cellType: StoreDetailCell.self
            )) { index, imageUrl, cell in
                cell.configure(with: imageUrl)
            }
            .disposed(by: disposeBag)

        // State - 디버깅용
        reactor.state.map { $0.menus }
            .distinctUntilChanged { $0.count == $1.count }
            .subscribe(onNext: { [weak self] menus in
                guard let self = self else { return }

                print("📱 ProductDetail loaded with \(menus.count) menus")
                menus.forEach { menu in
                    print("  - \(menu.name) (tags: \(menu.tags))")
                }

                // 임시로 메뉴 정보 출력
                let menuCount = menus.count
                let firstMenuName = menus.first?.name ?? "N/A"
                self.mainView.testLabel.text = "메뉴 \(menuCount)개\n첫 번째: \(firstMenuName)"
            })
            .disposed(by: disposeBag)
    }
}
