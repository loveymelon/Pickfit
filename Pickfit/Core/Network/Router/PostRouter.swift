//
//  PostRouter.swift
//  Pickfit
//
//  Created by 김진수 on 2025-10-20.
//

import Foundation
import Alamofire

enum PostRouter: Router {
    case fetchPostsByGeolocation(
        category: String,
        longitude: Double,
        latitude: Double,
        maxDistance: String?,
        limit: Int,
        next: String?,
        orderBy: String
    )
    case fetchPostDetail(postId: String)
    case createComment(postId: String, request: CreateCommentRequestDTO)
}

extension PostRouter {
    var method: HTTPMethod {
        switch self {
        case .fetchPostsByGeolocation, .fetchPostDetail:
            return .get
        case .createComment:
            return .post
        }
    }

    var path: String {
        switch self {
        case .fetchPostsByGeolocation:
            return "/posts/geolocation"
        case .fetchPostDetail(let postId):
            return "/posts/\(postId)"
        case .createComment(let postId, _):
            return "/posts/\(postId)/comments"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        return HTTPHeaders([
            HTTPHeader(name: "Content-Type", value: "application/json"),
            HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey)
        ])
    }

    var parameters: Parameters? {
        switch self {
        case .fetchPostsByGeolocation(
            let category,
            let longitude,
            let latitude,
            let maxDistance,
            let limit,
            let next,
            let orderBy
        ):
            var params: [String: Any] = [
                "category": category,
                "longitude": longitude,
                "latitude": latitude,
                "limit": limit,
                "order_by": orderBy
            ]

            if let maxDistance = maxDistance {
                params["maxDistance"] = maxDistance
            }

            if let next = next {
                params["next"] = next
            }

            return params

        case .fetchPostDetail, .createComment:
            return nil  // path parameter만 사용
        }
    }

    var body: Data? {
        switch self {
        case .createComment(_, let request):
            return try? JSONEncoder().encode(request)
        default:
            return nil
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .fetchPostsByGeolocation, .fetchPostDetail:
            return .url
        case .createComment:
            return .json
        }
    }
}
