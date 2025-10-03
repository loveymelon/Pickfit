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

        reactor.state.map { $0.stores }
            .distinctUntilChanged()
            .bind(to: mainView.collectionView.rx.items(
                cellIdentifier: HomeMainCell.identifier,
                cellType: HomeMainCell.self
            )) { index, store, cell in
                cell.configure(with: store)
            }
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
}
