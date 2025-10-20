//
//  CommunityReactor.swift
//  Pickfit
//
//  Created by Claude on 2025-10-20.
//

import Foundation
import ReactorKit
import RxSwift

final class CommunityReactor: Reactor {

    enum Action {
        case viewDidLoad
        case refresh
    }

    enum Mutation {
        case setItems([CommunityItem])
        case setLoading(Bool)
    }

    struct State {
        var items: [CommunityItem] = []
        var isLoading: Bool = false
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        print("🔵 [CommunityReactor] mutate called with action: \(action)")
        switch action {
        case .viewDidLoad, .refresh:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                loadMockData().map { .setItems($0) },
                Observable.just(.setLoading(false))
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setItems(let items):
            print("🔵 [CommunityReactor] setItems: \(items.count) items")
            newState.items = items

        case .setLoading(let isLoading):
            print("🔵 [CommunityReactor] setLoading: \(isLoading)")
            newState.isLoading = isLoading
        }

        return newState
    }

    private func loadMockData() -> Observable<[CommunityItem]> {
        print("🔵 [CommunityReactor] loadMockData called")
        // Mock 데이터 생성
        let mockItems: [CommunityItem] = [
            CommunityItem(id: "1", imageUrl: "https://picsum.photos/300/250", title: "오늘의 OOTD", userName: "fashionista", likeCount: 124, height: 250),
            CommunityItem(id: "2", imageUrl: "https://picsum.photos/300/300", title: "가을 스타일링 추천", userName: "styleking", likeCount: 89, height: 300),
            CommunityItem(id: "3", imageUrl: "https://picsum.photos/300/220", title: "캐주얼 룩북", userName: "dailylook", likeCount: 256, height: 220),
            CommunityItem(id: "4", imageUrl: "https://picsum.photos/300/280", title: "데이트 코디", userName: "lovelydate", likeCount: 178, height: 280),
            CommunityItem(id: "5", imageUrl: "https://picsum.photos/300/320", title: "겨울 패딩 추천", userName: "winterstyle", likeCount: 312, height: 320),
            CommunityItem(id: "6", imageUrl: "https://picsum.photos/300/240", title: "미니멀 스타일", userName: "minimal_life", likeCount: 203, height: 240),
            CommunityItem(id: "7", imageUrl: "https://picsum.photos/300/270", title: "스트릿 패션", userName: "streetfashion", likeCount: 145, height: 270),
            CommunityItem(id: "8", imageUrl: "https://picsum.photos/300/290", title: "빈티지 코디", userName: "vintage_lover", likeCount: 267, height: 290),
            CommunityItem(id: "9", imageUrl: "https://picsum.photos/300/230", title: "오피스 룩", userName: "office_style", likeCount: 98, height: 230),
            CommunityItem(id: "10", imageUrl: "https://picsum.photos/300/310", title: "주말 나들이 코디", userName: "weekend_ootd", likeCount: 187, height: 310),
        ]

        print("🔵 [CommunityReactor] Mock data created: \(mockItems.count) items")
        return Observable.just(mockItems).delay(.milliseconds(500), scheduler: MainScheduler.instance)
    }
}

// MARK: - Models

struct CommunityItem {
    let id: String
    let imageUrl: String
    let title: String
    let userName: String
    let likeCount: Int
    let height: CGFloat
}
