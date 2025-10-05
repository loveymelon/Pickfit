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
    case refreshToken(RefreshTokenRequestDTO)
}

extension LoginRouter {
    var method: HTTPMethod {
        switch self {
        case .kakaoLogin:
            return .post
        case .refreshToken:
            return .get
        }
    }

    var path: String {
        switch self {
        case .kakaoLogin:
            return "/users/login/kakao"
        case .refreshToken:
            return "/auth/refresh"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        switch self {
        case .kakaoLogin:
            return HTTPHeaders([
                HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey),
                HTTPHeader(name: "accept", value: "application/json")
            ])
        case let .refreshToken(requestDTO):
            return HTTPHeaders([
                HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey),
                HTTPHeader(name: "accept", value: "application/json"),
                HTTPHeader(name: "Authorization", value: requestDTO.accessToken),
                HTTPHeader(name: "RefreshToken", value: requestDTO.refreshToken)
            ])
        }
    }

    var parameters: Parameters? {
        switch self {
        case .kakaoLogin:
            return nil
        case .refreshToken:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case let .kakaoLogin(requestDTO):
            return requestToBody(requestDTO)
        case .refreshToken:
            return nil
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .kakaoLogin:
            return .json
        case .refreshToken:
            return .url
        }
    }
}
