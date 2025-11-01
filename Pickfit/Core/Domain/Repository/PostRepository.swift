//
//  PostRepository.swift
//  Pickfit
//
//  Created by 김진수 on 2025-10-20.
//

import Foundation

final class PostRepository {

    enum OrderBy: String {
        case createdAt = "createdAt"
        case likes = "likes"
    }

    /// 위치 기반 게시글 조회
    /// - Parameters:
    ///   - category: 게시글 카테고리
    ///   - longitude: 경도
    ///   - latitude: 위도
    ///   - maxDistance: 최대 반경(미터), nil이면 전체
    ///   - limit: 한 페이지당 개수 (기본값: 5)
    ///   - next: 다음 페이지 커서
    ///   - orderBy: 정렬 기준 (createdAt: 최신순, likes: 좋아요 많은 순)
    func fetchPostsByGeolocation(
        category: String,
        longitude: Double,
        latitude: Double,
        maxDistance: String? = nil,
        limit: Int = 5,
        next: String? = nil,
        orderBy: OrderBy = .createdAt
    ) async throws -> PostListResponseDTO {
        let dto = try await NetworkManager.shared.fetch(
            dto: PostListResponseDTO.self,
            router: PostRouter.fetchPostsByGeolocation(
                category: category,
                longitude: longitude,
                latitude: latitude,
                maxDistance: maxDistance,
                limit: limit,
                next: next,
                orderBy: orderBy.rawValue
            )
        )

        return dto
    }

    /// 게시글 상세 조회
    /// - Parameter postId: 게시글 ID
    func fetchPostDetail(postId: String) async throws -> PostDetailResponseDTO {
        let dto = try await NetworkManager.shared.fetch(
            dto: PostDetailResponseDTO.self,
            router: PostRouter.fetchPostDetail(postId: postId)
        )

        return dto
    }

    /// 댓글 작성
    /// - Parameters:
    ///   - postId: 게시글 ID
    ///   - content: 댓글 내용
    ///   - parentCommentId: 부모 댓글 ID (대댓글일 경우)
    func createComment(
        postId: String,
        content: String,
        parentCommentId: String? = nil
    ) async throws -> CreateCommentResponseDTO {
        let request = CreateCommentRequestDTO(
            content: content,
            parentCommentId: parentCommentId
        )

        let dto = try await NetworkManager.shared.fetch(
            dto: CreateCommentResponseDTO.self,
            router: PostRouter.createComment(postId: postId, request: request)
        )

        return dto
    }
}
