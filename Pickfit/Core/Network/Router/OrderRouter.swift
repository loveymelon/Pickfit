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
    case validatePayment(impUid: String)
    case fetchOrderList
}

extension OrderRouter {
    var method: HTTPMethod {
        switch self {
        case .createOrder, .validatePayment:
            return .post
        case .fetchOrderList:
            return .get
        }
    }

    var path: String {
        switch self {
        case .createOrder, .fetchOrderList:
            return "/orders"
        case .validatePayment:
            return "/payments/validation"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        switch self {
        case .createOrder, .validatePayment, .fetchOrderList:
            return HTTPHeaders([
                HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey),
                HTTPHeader(name: "Content-Type", value: "application/json"),
                HTTPHeader(name: "accept", value: "application/json")
            ])
        }
    }

    var parameters: Parameters? {
        switch self {
        case .createOrder, .validatePayment, .fetchOrderList:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case let .createOrder(request):
            return requestToBody(request)
        case let .validatePayment(impUid):
            let bodyDict: [String: Any] = ["imp_uid": impUid]
            return try? JSONSerialization.data(withJSONObject: bodyDict)
        case .fetchOrderList:
            return nil
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .createOrder, .validatePayment:
            return .json
        case .fetchOrderList:
            return .url
        }
    }
}

