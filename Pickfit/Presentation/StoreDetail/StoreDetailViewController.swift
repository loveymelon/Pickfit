//
//  StoreDetailViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit
import RxDataSources

struct StoreDetailSection {
    var header: StoreDetailEntity?
    var items: [Item]
}

extension StoreDetailSection: SectionModelType {
    typealias Item = StoreDetailItem

    init(original: StoreDetailSection, items: [Item]) {
        self = original
        self.items = items
    }
}

enum StoreDetailItem {
    case image(String)
    case category(String)
    case product(ProductModel)
}

enum ProductCategory: String, CaseIterable {
    case all = "전체"
    case outer = "아우터"
    case top = "상의"
    case pants = "팬츠"
    case shoes = "신발"
}

final class StoreDetailViewController: BaseViewController<StoreDetailView> {
    var disposeBag = DisposeBag()

    private let reactor: StoreDetailReactor

    init(storeId: String) {
        self.reactor = StoreDetailReactor(storeId: storeId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.collectionView.setCollectionViewLayout(makeCollectionView(), animated: false)
        configureNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func configureNavigationBar() {
        // 네비게이션 바 투명하게 설정
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = nil

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = true
    }

    override func bind() {
        super.bind()

        rx.viewDidLoad
            .map { StoreDetailReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        rx.viewIsAppearing
            .map { StoreDetailReactor.Action.viewIsAppearing }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.shouldNavigateToLogin }
            .filter { $0 }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.navigateToLogin()
            })
            .disposed(by: disposeBag)

        // DataSource 설정
        let dataSource = RxCollectionViewSectionedReloadDataSource<StoreDetailSection>(
            configureCell: { dataSource, collectionView, indexPath, item in
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

                case .category(let title):
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: CategoryCell.identifier,
                        for: indexPath
                    ) as? CategoryCell else {
                        return UICollectionViewCell()
                    }
                    cell.configure(with: title)
                    return cell

                case .product(let productModel):
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: StoreProductCell.identifier,
                        for: indexPath
                    ) as? StoreProductCell else {
                        return UICollectionViewCell()
                    }
                    cell.configure(with: productModel)
                    return cell
                }
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                if kind == UICollectionView.elementKindSectionHeader {
                    guard let header = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: StoreHeaderView.reuseID,
                        for: indexPath
                    ) as? StoreHeaderView else {
                        return UICollectionReusableView()
                    }

                    if let storeDetail = dataSource.sectionModels[indexPath.section].header {
                        header.configure(with: storeDetail)
                    }

                    return header
                }
                return UICollectionReusableView()
            }
        )

        // 섹션 데이터 바인딩
        reactor.state.compactMap { $0.storeDetail }
            .distinctUntilChanged { $0.storeId == $1.storeId }
            .map { storeDetail -> [StoreDetailSection] in
                // Section 0: 이미지 섹션 (헤더 포함)
                let imageItems = storeDetail.storeImageUrls.map { StoreDetailSection.Item.image($0) }
                let imageSection = StoreDetailSection(header: storeDetail, items: imageItems)

                // Section 1: 카테고리 섹션 (고정된 카테고리)
                let categoryItems = ProductCategory.allCases.map { StoreDetailSection.Item.category($0.rawValue) }
                let categorySection = StoreDetailSection(header: nil, items: categoryItems)

                // Section 2: 상품 리스트 섹션 (TODO: 실제 상품 데이터로 교체)
                let dummyProducts: [ProductModel] = (0..<10).map { index in
                    ProductModel(
                        imageUrl: storeDetail.storeImageUrls.first,
                        title: "상품 \(index + 1)",
                        priceText: "50,000원",
                        discountPercent: index % 2 == 0 ? 20 : nil,
                        isLiked: false
                    )
                }
                let productItems = dummyProducts.map { StoreDetailSection.Item.product($0) }
                let productSection = StoreDetailSection(header: nil, items: productItems)

                return [imageSection, categorySection, productSection]
            }
            .bind(to: mainView.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }

    private func navigateToLogin() {
        NotificationCenter.default.post(name: .navigateToLogin, object: nil)
    }
    
    private func makeCollectionView() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex,_) -> NSCollectionLayoutSection? in
            return self.createSection(for: sectionIndex)
        }
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 18
        layout.configuration = config
        
        return layout
    }
    
    private func createSection(for sectionIndex: Int) -> NSCollectionLayoutSection {
        switch sectionIndex {
        case 0:
            return createMainSection()

        case 1:
            return createCategorySection()

        case 2:
            return createItemListSection()

        default:
            assertionFailure("Unexpected section index: \(sectionIndex)")
            return createMainSection() // fallback
        }
    }
    
    private func createMainSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )
        item.contentInsets = .zero

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(0.5)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .paging
        section.interGroupSpacing = 0
        section.contentInsets = .zero

        return section
    }

    private func createCategorySection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .estimated(80),
                heightDimension: .absolute(36)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .estimated(80),
                heightDimension: .absolute(36)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 8
        section.contentInsets = .init(top: 16, leading: 20, bottom: 16, trailing: 20)

        return section
    }

    private func createItemListSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(0.5),
                              heightDimension: .estimated(240))
        )
        item.contentInsets = .init(top: 0, leading: 8, bottom: 12, trailing: 8)
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                              heightDimension: .estimated(240)),
            subitems: [item, item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 12, bottom: 16, trailing: 12)
        
        // 헤더 추가
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        
        return section
    }
}
