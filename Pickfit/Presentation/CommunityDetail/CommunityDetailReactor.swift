//
//  CommunityDetailReactor.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-06.
//

import Foundation
import ReactorKit
import RxSwift

final class CommunityDetailReactor: Reactor {

    enum Action {
        case viewDidLoad
        case tappedArchiveButton
        case tappedCopyAddress
        case tappedSubmitComment
        case updateCommentText(String)
        case deleteComment(Int)  // index
        case reportComment(Int)  // index
        case tappedMoreButton
        case tappedDeletePost
        case tappedEditPost
        case tappedReportPost
        case reportUser
        case refresh
        case profileTapped  // 프로필 영역 탭
        case startChat  // 채팅 시작
    }

    enum Mutation {
        case setSpotDetail(SpotDetailEntity)
        case setComments([CommentEntity])
        case setCommentText(String)
        case setIsArchived(Bool)
        case setLoading(Bool)
        case setError(String?)
        case appendComment(CommentEntity)
        case removeComment(Int)
        case setCurrentImageIndex(Int)
        case setCreatedChatRoomInfo(roomId: String, nickname: String, profileImage: String?)  // 채팅방 생성 결과
        case showProfileBottomSheet  // 프로필 바텀시트 표시
    }

    struct State {
        var spotDetail: SpotDetailEntity?
        var comments: [CommentEntity] = []
        var commentText: String = ""
        var isArchived: Bool = false
        var isLoading: Bool = false
        var errorMessage: String?
        var currentImageIndex: Int = 0
        var isAuthor: Bool = false  // 작성자 여부
        var createdChatRoomInfo: (roomId: String, nickname: String, profileImage: String?)?  // 채팅방 생성 결과
        var shouldShowProfileBottomSheet: Bool = false  // 프로필 바텀시트 표시 여부
    }

    let initialState = State()
    private let postId: String
    private let postRepository = PostRepository()
    private let chatRepository = ChatRepository()

    init(postId: String) {
        self.postId = postId
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad, .refresh:
            return fetchSpotDetail()

        case .tappedArchiveButton:
            return toggleArchive()

        case .tappedCopyAddress:
            // ViewController에서 처리
            return .empty()

        case .tappedSubmitComment:
            return submitComment()

        case .updateCommentText(let text):
            return .just(.setCommentText(text))

        case .deleteComment(let index):
            return deleteComment(at: index)

        case .reportComment(let index):
            return reportComment(at: index)

        case .tappedMoreButton:
            // BottomSheet 표시 로직 (ViewController에서 처리)
            return .empty()

        case .tappedDeletePost:
            return deletePost()

        case .tappedEditPost:
            // 수정 화면으로 이동 (ViewController에서 처리)
            return .empty()

        case .tappedReportPost:
            return reportPost()

        case .reportUser:
            return reportUser()

        case .profileTapped:
            return .just(.showProfileBottomSheet)

        case .startChat:
            return startChat()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSpotDetail(let detail):
            newState.spotDetail = detail
            newState.isArchived = detail.isScraped
            newState.isAuthor = detail.isAuthor
            newState.isLoading = false

        case .setComments(let comments):
            newState.comments = comments

        case .setCommentText(let text):
            newState.commentText = text

        case .setIsArchived(let isArchived):
            newState.isArchived = isArchived
            newState.spotDetail?.isScraped = isArchived

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.errorMessage = error
            newState.isLoading = false

        case .appendComment(let comment):
            newState.comments.append(comment)
            newState.commentText = ""

        case .removeComment(let index):
            guard index < newState.comments.count else { break }
            newState.comments.remove(at: index)

        case .setCurrentImageIndex(let index):
            newState.currentImageIndex = index

        case .setCreatedChatRoomInfo(let roomId, let nickname, let profileImage):
            newState.createdChatRoomInfo = (roomId, nickname, profileImage)

        case .showProfileBottomSheet:
            newState.shouldShowProfileBottomSheet = true
        }

        return newState
    }

    // MARK: - Private Methods

    private func fetchSpotDetail() -> Observable<Mutation> {
        return .concat([
            .just(.setLoading(true)),
            run(
                operation: { send in
                    let dto = try await self.postRepository.fetchPostDetail(postId: self.postId)
                    let detail = self.convertToSpotDetailEntity(dto)
                    let comments = self.convertToCommentEntities(dto.comments)

                    send(.setSpotDetail(detail))
                    send(.setComments(comments))
                },
                onError: { error in
                    return .setError(error.localizedDescription)
                }
            )
        ])
    }

    private func toggleArchive() -> Observable<Mutation> {
        let newState = !currentState.isArchived
        // TODO: API 호출
        return .just(.setIsArchived(newState))
    }


    private func submitComment() -> Observable<Mutation> {
        let text = currentState.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .empty() }

        return run(
            operation: { send in
                let dto = try await self.postRepository.createComment(
                    postId: self.postId,
                    content: text,
                    parentCommentId: nil
                )

                let currentUserId = await KeychainAuthStorage.shared.readUserId() ?? ""

                let newComment = CommentEntity(
                    reviewId: Int(dto.commentId.hashValue),
                    memberName: dto.creator.nick,
                    reviewText: dto.content,
                    reviewDate: self.formatDate(dto.createdAt),
                    isAuthor: dto.creator.userId == currentUserId
                )

                send(.appendComment(newComment))
            },
            onError: { error in
                return .setError(error.localizedDescription)
            }
        )
    }

    private func deleteComment(at index: Int) -> Observable<Mutation> {
        guard index < currentState.comments.count else { return .empty() }
        // TODO: API 호출
        return .just(.removeComment(index))
    }

    private func reportComment(at index: Int) -> Observable<Mutation> {
        guard index < currentState.comments.count else { return .empty() }
        // TODO: API 호출
        return .empty()
    }

    private func deletePost() -> Observable<Mutation> {
        // TODO: API 호출
        return .empty()
    }

    private func reportPost() -> Observable<Mutation> {
        // TODO: API 호출
        return .empty()
    }

    private func reportUser() -> Observable<Mutation> {
        // TODO: API 호출
        return .empty()
    }

    private func startChat() -> Observable<Mutation> {
        guard let authorId = currentState.spotDetail?.authorId else {
            print("❌ [CommunityDetailReactor] authorId가 없습니다")
            return .just(.setError("작성자 정보를 찾을 수 없습니다"))
        }

        return run(
            operation: { [weak self] send in
                guard let self else { return }

                print("🚀 [CommunityDetailReactor] 채팅방 생성 시작 - opponentId: \(authorId)")

                let roomInfo = try await self.chatRepository.createOrFetchChatRoom(opponentId: authorId)

                print("✅ [CommunityDetailReactor] 채팅방 생성 완료 - roomId: \(roomInfo.roomId), nickname: \(roomInfo.nickname)")

                send(.setCreatedChatRoomInfo(
                    roomId: roomInfo.roomId,
                    nickname: roomInfo.nickname,
                    profileImage: roomInfo.profileImage
                ))
            },
            onError: { error in
                print("❌ [CommunityDetailReactor] 채팅방 생성 실패: \(error.localizedDescription)")
                return .setError("채팅방 생성에 실패했습니다")
            }
        )
    }

    // MARK: - Converters

    private func convertToSpotDetailEntity(_ dto: PostDetailResponseDTO) -> SpotDetailEntity {
        let currentUserId = KeychainAuthStorage.shared.readUserId() ?? ""

        return SpotDetailEntity(
            postId: dto.postId,
            title: dto.title,
            content: dto.content,
            storeName: dto.store?.name,
            authorId: dto.creator.userId,  // 작성자 user_id 추가
            authorName: dto.creator.nick,
            authorProfileImage: dto.creator.profileImage,
            tags: dto.store?.hashTags ?? [],
            images: dto.files,
            categoryId: dto.category,
            likeCount: dto.likeCount,
            createdAt: formatDate(dto.createdAt),
            isScraped: dto.isLike,
            isAuthor: dto.creator.userId == currentUserId
        )
    }

    private func convertToCommentEntities(_ dtos: [CommentDTO]) -> [CommentEntity] {
        let currentUserId = KeychainAuthStorage.shared.readUserId() ?? ""

        return dtos.map { dto in
            CommentEntity(
                reviewId: Int(dto.commentId.hashValue),  // commentId는 String이므로 hash로 변환
                memberName: dto.creator.nick,
                reviewText: dto.content,
                reviewDate: formatDate(dto.createdAt),
                isAuthor: dto.creator.userId == currentUserId
            )
        }
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: isoString) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: isoString) else {
                return isoString
            }

            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy년 MM월 dd일"
            displayFormatter.locale = Locale(identifier: "ko_KR")
            return displayFormatter.string(from: date)
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy년 MM월 dd일"
        displayFormatter.locale = Locale(identifier: "ko_KR")
        return displayFormatter.string(from: date)
    }
}

// MARK: - Mock Entities

struct SpotDetailEntity {
    let postId: String
    let title: String
    let content: String
    let storeName: String?
    let authorId: String  // 작성자 user_id (채팅방 생성용)
    let authorName: String
    let authorProfileImage: String?
    let tags: [String]
    let images: [String]
    let categoryId: String
    let likeCount: Int
    let createdAt: String
    var isScraped: Bool
    let isAuthor: Bool
}

struct CommentEntity {
    let reviewId: Int
    let memberName: String
    let reviewText: String
    let reviewDate: String
    let isAuthor: Bool

    static func mockList() -> [CommentEntity] {
        return [
            CommentEntity(reviewId: 1, memberName: "김진수", reviewText: "정말 좋은 곳이네요!", reviewDate: "2025.01.06", isAuthor: true),
            CommentEntity(reviewId: 2, memberName: "박지민", reviewText: "다음에 또 가고 싶어요", reviewDate: "2025.01.05", isAuthor: false),
            CommentEntity(reviewId: 3, memberName: "이수현", reviewText: "커피가 맛있어요", reviewDate: "2025.01.04", isAuthor: false)
        ]
    }
}

// MARK: - Helper Extension

extension Date {
    func toString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
