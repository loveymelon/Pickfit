//
//  CommunityReactor.swift
//  Pickfit
//
//  Created by 김진수 on 2025-10-20.
//

import Foundation
import ReactorKit
import RxSwift

final class CommunityReactor: Reactor {

    private let postRepository: PostRepository

    init(postRepository: PostRepository = PostRepository()) {
        self.postRepository = postRepository
    }

    enum Action {
        case viewDidLoad
        case viewIsAppearing
        case refresh
        case loadMore
    }

    enum Mutation {
        case setItems([CommunityItem])
        case appendItems([CommunityItem])
        case setLoading(Bool)
        case setLoadingMore(Bool)
        case setNextCursor(String)
        case setError(Error)
    }

    struct State {
        var items: [CommunityItem] = []
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var nextCursor: String = ""
        var errorMessage: String? = nil
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        print("🔵 [CommunityReactor] mutate called with action: \(action)")
        switch action {
        case .viewDidLoad:
            return Observable.empty()

        case .viewIsAppearing, .refresh:
            return run(
                operation: { [weak self] send in
                    guard let self else { return }

                    send(.setLoading(true))

                    // 현재 위치 (임시로 서울 중심부 좌표 사용)
                    let response = try await self.postRepository.fetchPostsByGeolocation(
                        category: "",
                        longitude: 127.0,
                        latitude: 37.5,
                        maxDistance: "500000", // 500km
                        limit: 20,
                        next: nil,
                        orderBy: .createdAt
                    )

                    print("✅ [CommunityReactor] Posts received: \(response.data.count) items")
                    print("✅ [CommunityReactor] Next cursor: \(response.nextCursor)")

                    let items = self.convertToItems(response.data)

                    send(.setItems(items))
                    send(.setNextCursor(response.nextCursor))
                    send(.setLoading(false))
                },
                onError: { error in
                    print("❌ [CommunityReactor] Error: \(error.localizedDescription)")
                    return .setError(error)
                }
            )

        case .loadMore:
            let currentState = self.currentState

            // 이미 로딩 중이거나 더 이상 페이지가 없으면 무시
            guard !currentState.isLoadingMore,
                  !currentState.nextCursor.isEmpty,
                  currentState.nextCursor != "0" else {
                print("🔵 [CommunityReactor] loadMore ignored - isLoadingMore: \(currentState.isLoadingMore), nextCursor: \(currentState.nextCursor)")
                return Observable.empty()
            }

            return run(
                operation: { [weak self] send in
                    guard let self else { return }

                    send(.setLoadingMore(true))

                    let response = try await self.postRepository.fetchPostsByGeolocation(
                        category: "",
                        longitude: 127.0,
                        latitude: 37.5,
                        maxDistance: "500000",
                        limit: 20,
                        next: currentState.nextCursor,
                        orderBy: .createdAt
                    )

                    print("✅ [CommunityReactor] Load more - Posts received: \(response.data.count) items")
                    print("✅ [CommunityReactor] Load more - Next cursor: \(response.nextCursor)")

                    let items = self.convertToItems(response.data)

                    send(.appendItems(items))
                    send(.setNextCursor(response.nextCursor))
                    send(.setLoadingMore(false))
                },
                onError: { error in
                    print("❌ [CommunityReactor] Load more error: \(error.localizedDescription)")
                    return .setError(error)
                }
            )
        }
    }

    private func convertToItems(_ posts: [PostDTO]) -> [CommunityItem] {
        return posts.compactMap { post -> CommunityItem? in
            // 미디어 파일 확장자 정의
            let videoExtensions = [".mp4", ".mov", ".avi", ".mkv", ".wmv"]
            let imageExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp"]

            // files 배열에서 첫 번째 미디어 파일(이미지 또는 동영상) 찾기
            guard let mediaFile = post.files.first(where: { file in
                let lowercaseFile = file.lowercased()
                let isImage = imageExtensions.contains(where: { lowercaseFile.hasSuffix($0) })
                let isVideo = videoExtensions.contains(where: { lowercaseFile.hasSuffix($0) })
                return isImage || isVideo
            }) else {
                // 미디어 파일이 없으면 건너뜀
                print("⚠️ [Community] No media file found in post: \(post.postId)")
                return nil
            }

            // 동영상 여부 확인
            let isVideo = videoExtensions.contains(where: { mediaFile.lowercased().hasSuffix($0) })

            // URL 생성
            let mediaUrl: String
            if mediaFile.hasPrefix("http") {
                mediaUrl = mediaFile
            } else {
                mediaUrl = APIKey.baseURL + mediaFile
            }

            print("✅ [Community] Media file found - isVideo: \(isVideo), url: \(mediaUrl)")

            // 높이는 랜덤으로 설정 (폭포수 레이아웃용)
            let height = CGFloat.random(in: 220...320)

            return CommunityItem(
                id: post.postId,
                imageUrl: mediaUrl,
                isVideo: isVideo,
                title: post.title,
                userName: post.creator.nick,
                likeCount: post.likeCount,
                height: height
            )
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setItems(let items):
            print("🔵 [CommunityReactor] setItems: \(items.count) items")
            newState.items = items
            newState.errorMessage = nil

        case .appendItems(let items):
            print("🔵 [CommunityReactor] appendItems: \(items.count) items, total: \(newState.items.count + items.count)")
            newState.items.append(contentsOf: items)
            newState.errorMessage = nil

        case .setLoading(let isLoading):
            print("🔵 [CommunityReactor] setLoading: \(isLoading)")
            newState.isLoading = isLoading

        case .setLoadingMore(let isLoadingMore):
            print("🔵 [CommunityReactor] setLoadingMore: \(isLoadingMore)")
            newState.isLoadingMore = isLoadingMore

        case .setNextCursor(let cursor):
            print("🔵 [CommunityReactor] setNextCursor: \(cursor)")
            newState.nextCursor = cursor

        case .setError(let error):
            newState.isLoading = false
            newState.isLoadingMore = false
            newState.errorMessage = error.localizedDescription
        }

        return newState
    }
}

// MARK: - Models

struct CommunityItem {
    let id: String
    let imageUrl: String
    let isVideo: Bool
    let title: String
    let userName: String
    let likeCount: Int
    let height: CGFloat
}
