//
//  PostRouter.swift
//  Pickfit
//
//  Created by Claude on 2025-10-20.
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
}

extension PostRouter {
    var method: HTTPMethod {
        switch self {
        case .fetchPostsByGeolocation:
            return .get
        }
    }

    var path: String {
        switch self {
        case .fetchPostsByGeolocation:
            return "/posts/geolocation"
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
        }
    }

    var body: Data? {
        return nil
    }

    var encodingType: EncodingType {
        switch self {
        case .fetchPostsByGeolocation:
            return .url
        }
    }
}
