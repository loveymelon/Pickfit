//
//  NetworkError.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import Foundation
import Alamofire

enum NetworkError: Error {
    case unauthorized  // 401, 418
    case serverError(AFError)

    var localizedDescription: String {
        switch self {
        case .unauthorized:
            return "인증이 만료되었습니다. 다시 로그인해주세요."
        case .serverError(let error):
            return error.localizedDescription
        }
    }
}