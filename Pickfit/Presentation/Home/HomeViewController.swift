//
//  HomeViewController.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit
import RxDataSources

final class HomeViewController: BaseViewController<HomeView> {

    var disposeBag = DisposeBag()

    private let reactor = HomeReactor()

    // 배너 자동 스크롤을 위한 Timer
    private var bannerTimer: Timer?
    private var currentBannerIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        mainView.collectionView.setCollectionViewLayout(makeCollectionView(), animated: false)
        // ⚠️ delegate를 수동으로 설정하면 RxSwift와 충돌
        // mainView.collectionView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startBannerAutoScroll()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopBannerAutoScroll()
    }

    deinit {
        stopBannerAutoScroll()
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: mainView.titleLabel)

        // 검색 버튼 추가
        let searchButton = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(searchButtonTapped)
        )
        searchButton.tintColor = .black

        // 하트 버튼 추가 (좋아요/피슐랭 기능)
//        let heartButton = UIBarButtonItem(
//            image: UIImage(systemName: "heart"),
//            style: .plain,
//            target: self,
//            action: #selector(heartButtonTapped)
//        )
//        heartButton.tintColor = .black
        // 우측부터 카트, 간격, 하트, 간격, 검색 순서로 배치
        if let cartButton = navigationItem.rightBarButtonItem {
            navigationItem.rightBarButtonItems = [cartButton, searchButton]
        }
    }

    @objc private func searchButtonTapped() {
        print("🔍 [Home] Search button tapped")
        // TODO: 검색 화면 이동 또는 검색 UI 표시
    }

    @objc private func heartButtonTapped() {
        print("❤️ [Home] Heart button tapped")
        // TODO: 좋아요/피슐랭 리스트 화면 이동
    }

    override func bind() {
        super.bind()

        rx.viewDidLoad
            .map { HomeReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        rx.viewIsAppearing
            .map { HomeReactor.Action.viewIsAppearing }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state.map { $0.shouldNavigateToLogin }
            .filter { $0 }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.navigateToLogin()
            })
            .disposed(by: disposeBag)

        let dataSource = RxCollectionViewSectionedReloadDataSource<HomeSectionModel>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                switch item {
                case .store(let store):
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: HomeMainCell.identifier,
                        for: indexPath
                    ) as? HomeMainCell else { return UICollectionViewCell() }
                    cell.configure(with: store)
                    return cell

                case .category(let category):
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: HomeCategoryCell.identifier,
                        for: indexPath
                    ) as? HomeCategoryCell else { return UICollectionViewCell() }
                    cell.configure(with: category)
                    return cell

                case .banner(let banner):
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: HomeBannerCell.identifier,
                        for: indexPath
                    ) as? HomeBannerCell else { return UICollectionViewCell() }
                    cell.configure(with: banner)
                    return cell

                case .stores(let store):
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: CategoryCapsuleCell.identifier,
                        for: indexPath
                    ) as? CategoryCapsuleCell else { return UICollectionViewCell() }

                    // 선택 상태 확인
                    let selectedIndex = self?.reactor.currentState.selectedBrandIndex ?? 0
                    let isSelected = (indexPath.item == selectedIndex)
                    cell.configure(image: store.storeImageUrls.last, text: store.name, isSelected: isSelected)

                    return cell

                case .product(let product):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoreProductCell.identifier, for: indexPath) as? StoreProductCell else { return UICollectionViewCell() }
                    cell.configure(with: product)
                    return cell
                }
            }
        )

        Observable.combineLatest(
            reactor.state.map { $0.stores }.distinctUntilChanged(),
            reactor.state.map { $0.categories }.distinctUntilChanged(),
            reactor.state.map { $0.banners }.distinctUntilChanged(),
            reactor.state.map { $0.menuList },
            reactor.state.map { $0.selectedBrandIndex }
        )
        .map { stores, categories, banners, menuList, _ -> [HomeSectionModel] in
            let products: [ProductModel]

            if !menuList.isEmpty {
                // menuList가 있으면 실제 메뉴 데이터 사용 (최대 6개)
                products = menuList
                    .prefix(6)
                    .compactMap { menu in
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
                // menuList가 없으면 더미 데이터 사용 (최대 6개)
                products = (0..<6).compactMap { index in
                    let tagCount = Int.random(in: 0...3)
                    guard tagCount < 2 else { return nil }

                    return ProductModel(
                        menuId: "dummy_\(index)",
                        imageUrl: stores.first?.storeImageUrls.first ?? "",
                        title: "상품 \(index + 1)",
                        priceText: "50,000원",
                        discountPercent: index % 2 == 0 ? 20 : nil,
                        isLiked: false,
                        tags: []
                    )
                }
            }

            return [
                .main(stores),
                .category(categories),
                .banner(banners),
                .stores(stores),
                .product(products)
            ]
        }
        .bind(to: mainView.collectionView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)

        // 셀 탭 이벤트
        mainView.collectionView.rx.itemSelected
            .withLatestFrom(
                Observable.combineLatest(
                    mainView.collectionView.rx.itemSelected,
                    mainView.collectionView.rx.modelSelected(HomeSectionItem.self)
                )
            )
            .subscribe(onNext: { [weak self] indexPath, item in
                guard let self = self else { return }

                switch item {
                case .category(let category):
                    self.navigateToStoreList(category: category)

                case .banner(let banner):
                    // 배너 클릭 시 WebView 처리
                    print("🎯 [Banner] Clicked - Type: \(banner.payload.type), Value: \(banner.payload.value)")
                    if banner.payload.type == "WEBVIEW" {
                        self.navigateToWebView(urlString: banner.payload.value)
                    }

                case .stores(let store):
                    // 브랜드 선택 이벤트
                    let stores = self.reactor.currentState.stores
                    if let storeIndex = stores.firstIndex(where: { $0.storeId == store.storeId }) {
                        self.reactor.action.onNext(.selectBrand(index: storeIndex, storeId: store.storeId))
                    }

                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        // 스크롤 이벤트 - 사용자 수동 스크롤 감지
        mainView.collectionView.rx.willBeginDragging
            .subscribe(onNext: { [weak self] _ in
                // 사용자가 수동으로 스크롤 시작하면 타이머 정지
                self?.stopBannerAutoScroll()
            })
            .disposed(by: disposeBag)

        mainView.collectionView.rx.didEndDragging
            .subscribe(onNext: { [weak self] _ in
                // 사용자가 스크롤 끝내면 타이머 재시작
                self?.startBannerAutoScroll()
            })
            .disposed(by: disposeBag)

        mainView.collectionView.rx.didEndDecelerating
            .subscribe(onNext: { [weak self] _ in
                // 배너 섹션의 현재 인덱스 업데이트
                self?.updateCurrentBannerIndex()
            })
            .disposed(by: disposeBag)

        mainView.collectionView.rx.didEndScrollingAnimation
            .subscribe(onNext: { [weak self] _ in
                // 자동 스크롤 완료 후 현재 인덱스 업데이트
                self?.updateCurrentBannerIndex()
            })
            .disposed(by: disposeBag)
    }

    private func navigateToLogin() {
        NotificationCenter.default.post(name: .navigateToLogin, object: nil)
    }

    private func navigateToStoreList(category: Category) {
        let storeListVC = StoreListViewController(category: category)
        navigationController?.pushViewController(storeListVC, animated: true)
    }

    private func navigateToWebView(urlString: String) {
        let webVC = WebViewController(urlString: urlString)
        navigationController?.pushViewController(webVC, animated: true)
    }

    // MARK: - Banner Auto Scroll

    private func startBannerAutoScroll() {
        // 기존 타이머 정리
        stopBannerAutoScroll()

        // 3초마다 배너 자동 넘김
        bannerTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollToNextBanner()
        }
    }

    private func stopBannerAutoScroll() {
        bannerTimer?.invalidate()
        bannerTimer = nil
    }

    private func scrollToNextBanner() {
        let bannerCount = reactor.currentState.banners.count
        guard bannerCount > 0 else { return }

        // 다음 배너 인덱스 계산 (무한 루프)
        currentBannerIndex = (currentBannerIndex + 1) % bannerCount

        // 배너 섹션 (section 2)으로 스크롤
        let indexPath = IndexPath(item: currentBannerIndex, section: 2)

        mainView.collectionView.scrollToItem(
            at: indexPath,
            at: .centeredHorizontally,
            animated: true
        )
    }

    private func updateCurrentBannerIndex() {
        // 배너 섹션(section 2)의 visible item 확인
        let visibleItems = mainView.collectionView.indexPathsForVisibleItems
            .filter { $0.section == 2 }

        if let firstVisibleItem = visibleItems.first {
            currentBannerIndex = firstVisibleItem.item
        }
    }
}

extension HomeViewController {
    private func makeCollectionView() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex,_) -> NSCollectionLayoutSection? in
            return self.createSection(for: sectionIndex)
        }
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 14
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
            return createBannerSection()
            
        case 3:
            return createLogoSection()
            
        case 4:
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
                heightDimension: .fractionalHeight(0.4)
            ),
            subitems: [item]
        )
        group.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .paging
        section.interGroupSpacing = 0
        section.contentInsets = .zero
        
        return section
    }
    
    private func createCategorySection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.18), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)

        return section
    }
    
    private func createBannerSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .zero
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.12))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .paging
        section.interGroupSpacing = 0
        section.contentInsets = .zero
        
        return section
    }
    
    private func createLogoSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(120),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .zero

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(120),
            heightDimension: .absolute(36)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 8
        section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)

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
