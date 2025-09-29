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

        mainView.collectionView.delegate = self
        mainView.collectionView.dataSource = self
        mainView.collectionView.setCollectionViewLayout(makeCollectionView(), animated: false)

        // ViewDidLoad 액션 전송
        reactor.action.onNext(.viewDidLoad)
    }

    override func bind() {
        super.bind()

        // 필요시 여기서 추가 바인딩
        // 예: 화면 전환, 데이터 로딩 등
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
            
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeMainCell.identifier, for: indexPath) as? HomeMainCell else { return UICollectionViewCell(frame: .zero) }
            
            return cell
            
        default:
            return UICollectionViewCell(frame: .zero)
        }
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
