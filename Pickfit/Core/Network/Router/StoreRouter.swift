//
//  StoreRouter.swift
//  Pickfit
//
//  Created by 김진수 on 10/3/25.
//

import Foundation
import Alamofire

enum StoreRouter: Router {
    case fetchStore(StoreRequestDTO)
}

extension StoreRouter {
    var method: HTTPMethod {
        switch self {
        case .fetchStore:
            return .get
        }
    }

    var path: String {
        switch self {
        case .fetchStore:
            return "/stores"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        switch self {
        case .fetchStore:
            return HTTPHeaders([
                HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey),
                HTTPHeader(name: "accept", value: "application/json")
            ])
        }
    }

    var parameters: Parameters? {
        switch self {
        case let .fetchStore(request):
            return try? request.asDictionary()
        }
    }

    var body: Data? {
        switch self {
        case .fetchStore:
            return nil
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .fetchStore:
            return .json
        }
    }
}
