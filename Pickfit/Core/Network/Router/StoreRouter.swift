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
    case fetchBanner
    case fetchStoreDetail(String)
}

extension StoreRouter {
    var method: HTTPMethod {
        switch self {
        case .fetchStore, .fetchBanner, .fetchStoreDetail:
            return .get
        }
    }

    var path: String {
        switch self {
        case .fetchStore:
            return "/stores"
            
        case .fetchBanner:
            return "/banners/main"
            
        case let .fetchStoreDetail(storeId):
            return "/stores/\(storeId)"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        switch self {
        case .fetchStore, .fetchBanner, .fetchStoreDetail:
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
            
        case .fetchBanner, .fetchStoreDetail:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .fetchStore, .fetchBanner, .fetchStoreDetail:
            return nil
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .fetchStore, .fetchStoreDetail:
            return .url
            
        case .fetchBanner:
            return .json
        }
    }
}
