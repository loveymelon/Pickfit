//
//  WebRouter.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-30.
//

import Foundation
import Alamofire

enum WebRouter: Router {
    case eventApplication
}

extension WebRouter {
    var method: HTTPMethod {
        switch self {
        case .eventApplication:
            return .get
        }
    }

    var baseURL: String {
        return APIKey.baseURL
    }

    var path: String {
        switch self {
        case .eventApplication:
            return "/event-application"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        switch self {
        case .eventApplication:
            return HTTPHeaders([
                HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey),
                HTTPHeader(name: "accept", value: "text/html")
            ])
        }
    }

    var parameters: Parameters? {
        return nil
    }

    var body: Data? {
        return nil
    }

    var encodingType: EncodingType {
        switch self {
        case .eventApplication:
            return .url
        }
    }
}
