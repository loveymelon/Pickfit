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
import RxDataSources

final class ProductDetailViewController: BaseViewController<ProductDetailView> {
    var disposeBag = DisposeBag()

    private let reactor: ProductDetailReactor

    private lazy var dataSource = RxCollectionViewSectionedReloadDataSource<ProductDetailSection>(
        configureCell: { [weak self] dataSource, collectionView, indexPath, item in
            guard let self = self else { return UICollectionViewCell() }

            switch item {
            case .image(let imageUrl):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: StoreDetailCell.identifier,
                    for: indexPath
                ) as? StoreDetailCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: imageUrl)
                return cell

            case .info(let productInfo):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ProductInfoCell.identifier,
                    for: indexPath
                ) as? ProductInfoCell else {
                    return UICollectionViewCell()
                }

                let selectedSize = self.reactor.currentState.selectedSize
                let selectedColor = self.reactor.currentState.selectedColor

                print("📦 ProductInfo - sizes: \(productInfo.sizes)")
                print("🎨 ProductInfo - colors: \(productInfo.colors)")

                cell.configure(with: productInfo, selectedSize: selectedSize, selectedColor: selectedColor)

                cell.onSizeSelected = { [weak self] size in
                    self?.reactor.action.onNext(.selectSize(size))
                }

                cell.onColorSelected = { [weak self] color in
                    self?.reactor.action.onNext(.selectColor(color))
                }

                return cell
            }
        }
    )

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

        // CollectionView 셀 등록
        mainView.collectionView.register(StoreDetailCell.self, forCellWithReuseIdentifier: StoreDetailCell.identifier)
        mainView.collectionView.register(ProductInfoCell.self, forCellWithReuseIdentifier: ProductInfoCell.identifier)
    }

    override func bind() {
        super.bind()

        rx.viewDidLoad
            .map { ProductDetailReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Sections 생성 및 바인딩
        reactor.state
            .map { state -> [ProductDetailSection] in
                var sections: [ProductDetailSection] = []

                // Section 0: 이미지
                let imageItems = state.imageUrls.map { ProductDetailItem.image($0) }
                sections.append(.images(imageItems))

                // Section 1: 상품 정보
                if let productInfo = state.productInfo {
                    sections.append(.productInfo([.info(productInfo)]))
                }

                return sections
            }
            .bind(to: mainView.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        // 사이즈와 색상 선택 여부에 따라 버튼 활성화/비활성화
        reactor.state
            .map { $0.selectedSize != nil && $0.selectedColor != nil }
            .distinctUntilChanged()
            .bind(to: mainView.addToCartButton.rx.isEnabled)
            .disposed(by: disposeBag)

        // 버튼 스타일 변경 (활성화/비활성화)
        reactor.state
            .map { $0.selectedSize != nil && $0.selectedColor != nil }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isEnabled in
                self?.mainView.addToCartButton.backgroundColor = isEnabled ? .black : .systemGray4
                self?.mainView.addToCartButton.alpha = isEnabled ? 1.0 : 0.6
            })
            .disposed(by: disposeBag)

        // 장바구니 담기 버튼
        mainView.addToCartButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleAddToCart()
            })
            .disposed(by: disposeBag)
    }

    private func handleAddToCart() {
        // TODO: 장바구니 담기 로직 구현
        showAlert(message: "장바구니에 담겼습니다")
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
