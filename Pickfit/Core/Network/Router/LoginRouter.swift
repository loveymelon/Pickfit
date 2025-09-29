//
//  LoginRouter.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation
import Alamofire

enum LoginRouter: Router {
    case kakaoLogin(KakaoRequestDTO)
}

extension LoginRouter {
    var method: HTTPMethod {
        switch self {
        case .kakaoLogin:
            return .post
        }
    }

    var path: String {
        switch self {
        case .kakaoLogin:
            return "/users/login/kakao"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        switch self {
        case .kakaoLogin:
            return HTTPHeaders([
                HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey),
                HTTPHeader(name: "accept", value: "application/json")
            ])
        }
    }

    var parameters: Parameters? {
        switch self {
        case .kakaoLogin:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case let .kakaoLogin(requestDTO):
            return requestToBody(requestDTO)
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .kakaoLogin:
            return .json
        }
    }
}
