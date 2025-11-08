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
    case bag = "가방"
    case jewellery = "장신구"
    case trailing = "트레이닝"
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

        // 더미 장바구니 데이터 자동 추가
        addDummyCartItems()
    }

    private func addDummyCartItems() {
        // 현재 장바구니가 비어있을 때만 더미 데이터 추가
        guard CartManager.shared.currentCartItems.isEmpty else { return }

        // 더미 메뉴 데이터 생성 (6개)
        let dummyMenus: [(name: String, price: Int, size: String, color: String, imageName: String?)] = [
            ("나이키 에어포스 1", 129000, "270", "화이트", "에어포스 1"),
            ("아디다스 슈퍼스타", 119000, "265", "블랙", "슈퍼스타"),
            ("컨버스 척테일러", 89000, "280", "레드", "척테일러"),
            ("반스 올드스쿨", 79000, "275", "네이비", "올드스쿨"),
            ("뉴발란스 530", 139000, "270", "그레이", "530"),
            ("푸마 스웨이드", 99000, "265", "그린", nil)
        ]

        // 각 더미 메뉴를 장바구니에 추가
        for (index, dummy) in dummyMenus.enumerated() {
            let dummyMenu = StoreDetailEntity.Menu(
                menuId: "dummy_\(index)",
                storeId: "dummy_store",
                category: "신발",
                name: dummy.name,
                description: "더미 상품입니다",
                originInformation: "",
                price: dummy.price,
                isSoldOut: false,
                tags: [],
                menuImageUrl: dummy.imageName ?? "",  // 로컬 이미지 이름
                createdAt: "",
                updatedAt: ""
            )

            CartManager.shared.addToCart(
                menu: dummyMenu,
                size: dummy.size,
                color: dummy.color
            )
        }

        print("✅ 더미 장바구니 데이터 6개 추가 완료")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        tabBarController?.tabBar.isHidden = true
    }

    private func configureNavigationBar() {
        // 네비게이션 바 투명하게 설정 (초기 상태)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = nil

        let backButton = UIBarButtonItem(
            image: UIImage(named: "chevron"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
        navigationItem.hidesBackButton = true

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = true

        // 초기에는 타이틀 숨김
        title = nil
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
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
            .do(onNext: { [weak self] _ in
                // 첫 번째 카테고리(전체)를 기본 선택
                DispatchQueue.main.async {
                    self?.mainView.collectionView.selectItem(
                        at: IndexPath(item: 0, section: 1),
                        animated: false,
                        scrollPosition: []
                    )
                }
            })
            .map { storeDetail -> [StoreDetailSection] in
                // Section 0: 이미지 섹션 (헤더 포함)
                let imageItems = storeDetail.storeImageUrls.map { StoreDetailSection.Item.image($0) }
                let imageSection = StoreDetailSection(header: storeDetail, items: imageItems)

                // Section 1: 카테고리 섹션 (고정된 카테고리)
                let categoryItems = ProductCategory.allCases.map { StoreDetailSection.Item.category($0.rawValue) }
                let categorySection = StoreDetailSection(header: nil, items: categoryItems)

                // Section 2: 상품 리스트 섹션
                let products: [ProductModel]
                if !storeDetail.menuList.isEmpty {
                    // menuList가 있으면 실제 메뉴 데이터 사용
                    products = storeDetail.menuList.compactMap { menu in
                        // tag가 2개 이상이면 필터링
                        guard menu.tags.count < 2 else { return nil }

                        return ProductModel(
                            menuId: menu.menuId,
                            imageUrl: menu.menuImageUrl,
                            title: menu.name,
                            priceText: "\(menu.price)원",
                            discountPercent: nil,
                            isLiked: false,
                            tags: menu.tags
                        )
                    }
                } else {
                    // menuList가 없으면 더미 데이터 사용
                    products = (0..<10).compactMap { index in
                        let tagCount = Int.random(in: 0...3)
                        guard tagCount < 2 else { return nil }

                        return ProductModel(
                            menuId: "dummy_\(index)",
                            imageUrl: storeDetail.storeImageUrls.first,
                            title: "상품 \(index + 1)",
                            priceText: "50,000원",
                            discountPercent: index % 2 == 0 ? 20 : nil,
                            isLiked: false,
                            tags: []
                        )
                    }
                }

                let productItems = products.map { StoreDetailSection.Item.product($0) }
                let productSection = StoreDetailSection(header: nil, items: productItems)

                return [imageSection, categorySection, productSection]
            }
            .bind(to: mainView.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        // 장바구니 상태 변경 시 버튼 표시/숨김 및 정보 업데이트
        reactor.state.map { $0.cartItems }
            .subscribe(onNext: { [weak self] cartItems in
                print("\n🛒 === 장바구니 현황 ===")
                print("총 \(cartItems.count)개 종류")

                // 총 수량과 총 금액 계산
                var totalQuantity = 0
                var totalPrice = 0

                for (index, item) in cartItems.enumerated() {
                    print("  [\(index + 1)] \(item.menu.name)")
                    print("      사이즈: \(item.size), 색상: \(item.color), 수량: \(item.quantity)")
                    print("      가격: \(item.menu.price)원 × \(item.quantity) = \(item.menu.price * item.quantity)원")

                    totalQuantity += item.quantity
                    totalPrice += item.menu.price * item.quantity
                }

                print("총 수량: \(totalQuantity)개")
                print("총 금액: \(totalPrice)원")
                print("===================\n")

                // 장바구니가 비어있지 않으면 버튼 표시 및 정보 업데이트
                let shouldShowCart = !cartItems.isEmpty
                self?.mainView.setCartBottomViewVisible(shouldShowCart)

                if shouldShowCart {
                    self?.mainView.updateCartInfo(totalQuantity: totalQuantity, totalPrice: totalPrice)
                }
            })
            .disposed(by: disposeBag)

        // 상품 선택 처리
        mainView.collectionView.rx.modelSelected(StoreDetailItem.self)
            .withUnretained(self)
            .compactMap { owner, item -> [StoreDetailEntity.Menu]? in
                guard case .product(let productModel) = item else {
                    return nil
                }

                let menuId = productModel.menuId

                guard let menuList = owner.reactor.currentState.storeDetail?.menuList else {
                    return nil
                }

                let items = menuList.filter { $0.tags.contains(menuId) }

                guard let selectedMenu = menuList.first(where: { $0.menuId == menuId }) else {
                    return nil
                }

                return [selectedMenu] + items
            }
            .subscribe(onNext: { [weak self] menus in
                self?.navigateToProductDetail(menus: menus)
            })
            .disposed(by: disposeBag)

        // 장바구니 보기 버튼 탭 처리
        mainView.purchaseButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigateToShoppingCart()
            })
            .disposed(by: disposeBag)

        // 스크롤 위치에 따른 네비게이션 바 제목 표시/숨김
        mainView.collectionView.rx.contentOffset
            .withLatestFrom(reactor.state.compactMap { $0.storeDetail }) { ($0, $1) }
            .subscribe(onNext: { [weak self] offset, storeDetail in
                self?.updateNavigationBarAppearance(offset: offset, storeName: storeDetail.name)
            })
            .disposed(by: disposeBag)
    }

    private func updateNavigationBarAppearance(offset: CGPoint, storeName: String) {
        // 헤더 높이 (이미지 섹션)를 대략 계산
        // 화면 높이의 50% + 헤더 높이(약 200pt) = 임계값
        let thresholdY: CGFloat = UIScreen.main.bounds.height * 0.5 + 200 - 100

        if offset.y > thresholdY {
            // 스크롤 내려갔을 때 - 네비게이션 바 불투명 + 타이틀 표시
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.shadowColor = .systemGray5
            appearance.titleTextAttributes = [.foregroundColor: UIColor.black]

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance

            // 타이틀 표시 (애니메이션)
            if title != storeName {
                UIView.transition(with: navigationController?.navigationBar ?? UIView(),
                                  duration: 0.2,
                                  options: .transitionCrossDissolve) {
                    self.title = storeName
                }
            }
        } else {
            // 스크롤 위로 올라갔을 때 - 네비게이션 바 투명 + 타이틀 숨김
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = nil

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance

            // 타이틀 숨김
            if title != nil {
                UIView.transition(with: navigationController?.navigationBar ?? UIView(),
                                  duration: 0.2,
                                  options: .transitionCrossDissolve) {
                    self.title = nil
                }
            }
        }
    }

    private func navigateToProductDetail(menus: [StoreDetailEntity.Menu]) {
        let productDetailVC = ProductDetailViewController(menus: menus)

        // 장바구니 담기 Closure 설정
        productDetailVC.onAddToCart = { [weak self] menu, selectedSize, selectedColor in
            guard let self = self else { return }
            self.reactor.action.onNext(.addToCart(menu: menu, size: selectedSize, color: selectedColor))
        }

        navigationController?.pushViewController(productDetailVC, animated: true)
    }

    private func navigateToLogin() {
        NotificationCenter.default.post(name: .navigateToLogin, object: nil)
    }

    private func navigateToShoppingCart() {
        let shoppingCartVC = ShoppingCartViewController()
        navigationController?.pushViewController(shoppingCartVC, animated: true)
    }
    
    private func makeCollectionView() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex,_) -> NSCollectionLayoutSection? in
            return self.createSection(for: sectionIndex)
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 0
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
        
        // 헤더 추가
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .bottom
        )
        section.boundarySupplementaryItems = [header]

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

        return section
    }
}
