//
//  OrderRouter.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import Foundation
import Alamofire

enum OrderRouter: Router {
    case createOrder(OrderRequestDTO)
}

extension OrderRouter {
    var method: HTTPMethod {
        switch self {
        case .createOrder:
            return .post
        }
    }

    var path: String {
        switch self {
        case .createOrder:
            return "/orders"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        switch self {
        case .createOrder:
            return HTTPHeaders([
                HTTPHeader(name: "Content-Type", value: "application/json"),
                HTTPHeader(name: "accept", value: "application/json")
            ])
        }
    }

    var parameters: Parameters? {
        switch self {
        case .createOrder:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case let .createOrder(request):
            return requestToBody(request)
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .createOrder:
            return .json
        }
    }
}

