//
//  CommunityViewController.swift
//  Pickfit
//
//  Created by Claude on 2025-10-20.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

final class CommunityViewController: BaseViewController<CommunityView> {

    var disposeBag = DisposeBag()
    private let reactor = CommunityReactor()
    private let pinterestLayout = PinterestLayout()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()

        print("🔵 [Community VC] viewDidLoad")
        reactor.action.onNext(.viewDidLoad)
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        print("🔵 [Community VC] viewIsAppearing - triggering API call")
        reactor.action.onNext(.viewIsAppearing)
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: mainView.titleLabel)
    }

    private func setupCollectionView() {
        pinterestLayout.delegate = self
        mainView.collectionView.collectionViewLayout = pinterestLayout
        mainView.collectionView.register(CommunityCell.self, forCellWithReuseIdentifier: CommunityCell.identifier)
    }

    override func bind() {
        super.bind()

        print("🔵 [Community VC] bind() called")

        // CollectionView DataSource
        mainView.collectionView.dataSource = self

        // Output: Items
        reactor.state
            .map { $0.items }
            .do(onNext: { items in
                print("🔵 [Community] Items state changed: \(items.count)")
            })
            .subscribe(onNext: { [weak self] items in
                print("🔵 [Community] Reloading collection view with \(items.count) items")
                self?.pinterestLayout.invalidateLayout()
                self?.mainView.collectionView.reloadData()

                // 레이아웃 업데이트 후 contentSize 출력
                DispatchQueue.main.async {
                    let contentSize = self?.mainView.collectionView.contentSize ?? .zero
                    print("🔵 [Community] Updated contentSize: \(contentSize)")
                }
            })
            .disposed(by: disposeBag)

        // Cell Selection
        mainView.collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                print("Selected item at: \(indexPath)")
                // TODO: Navigate to detail view
            })
            .disposed(by: disposeBag)

        // Pagination: Scroll to bottom
        mainView.collectionView.rx.contentOffset
            .map { [weak self] offset -> Bool in
                guard let self = self else { return false }
                let collectionView = self.mainView.collectionView
                let contentHeight = collectionView.contentSize.height
                let scrollViewHeight = collectionView.bounds.height
                let scrollPosition = offset.y

                // 하단에서 200pt 이전에 도달하면 다음 페이지 로드
                let threshold: CGFloat = 200
                let shouldLoadMore = scrollPosition + scrollViewHeight >= contentHeight - threshold

                if shouldLoadMore && contentHeight > 0 {
                    print("📊 [Scroll] contentHeight: \(contentHeight), scrollViewHeight: \(scrollViewHeight), scrollPosition: \(scrollPosition)")
                    print("📊 [Scroll] Should load more: \(shouldLoadMore)")
                }

                return shouldLoadMore && contentHeight > 0
            }
            .distinctUntilChanged()
            .filter { $0 }
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                print("🔵 [Community] Reached bottom - triggering loadMore")
                print("🔵 [Community] Current state - isLoadingMore: \(self.reactor.currentState.isLoadingMore), nextCursor: \(self.reactor.currentState.nextCursor)")
                self.reactor.action.onNext(.loadMore)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UICollectionViewDataSource

extension CommunityViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = reactor.currentState.items.count
        print("🔵 [Community DataSource] numberOfItems: \(count)")
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CommunityCell.identifier,
            for: indexPath
        ) as? CommunityCell else {
            return UICollectionViewCell()
        }

        let items = reactor.currentState.items
        guard indexPath.item < items.count else { return cell }

        let item = items[indexPath.item]
        cell.configure(with: item)
        print("🔵 [Community DataSource] Configured cell at \(indexPath.item): \(item.title)")
        return cell
    }
}

// MARK: - PinterestLayoutDelegate

extension CommunityViewController: PinterestLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath) -> CGFloat {
        let items = reactor.currentState.items
        guard indexPath.item < items.count else { return 200 }
        return items[indexPath.item].height
    }
}
