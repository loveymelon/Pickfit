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

    override func viewDidLoad() {
        super.viewDidLoad()

        mainView.collectionView.setCollectionViewLayout(makeCollectionView(), animated: false)
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
            configureCell: { dataSource, collectionView, indexPath, item in
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
                }
            }
        )

        Observable.combineLatest(
            reactor.state.map { $0.stores }.distinctUntilChanged(),
            reactor.state.map { $0.categories }.distinctUntilChanged(),
            reactor.state.map { $0.banners }.distinctUntilChanged()
        )
        .map { stores, categories, banners -> [HomeSectionModel] in
            return [
                .main(stores),
                .category(categories),
                .banner(banners)
            ]
        }
        .bind(to: mainView.collectionView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
    }

    private func navigateToLogin() {
        NotificationCenter.default.post(name: .navigateToLogin, object: nil)
    }
}

extension HomeViewController {
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
            return createBannerSection()
            
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

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.22), heightDimension: .fractionalHeight(0.13))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)

        return section
    }
    
    private func createBannerSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 0, leading: 10, bottom: 0, trailing: 10)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.15))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        
        return section
    }
}
