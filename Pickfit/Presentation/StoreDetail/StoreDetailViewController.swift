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

        // 이미지 데이터 바인딩
        reactor.state.compactMap { $0.storeDetail?.storeImageUrls }
            .distinctUntilChanged()
            .bind(to: mainView.collectionView.rx.items(
                cellIdentifier: StoreDetailCell.identifier,
                cellType: StoreDetailCell.self
            )) { index, imageUrl, cell in
                cell.configure(with: imageUrl)
            }
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
            
//        case 1:
//            return createCategorySection()
            
//        case 2:
//            return createBannerSection()
            
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
                heightDimension: .fractionalHeight(0.45)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .paging
        section.interGroupSpacing = 0
        section.contentInsets = .zero
        
        return section
    }
}
