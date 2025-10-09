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

    // Socket Errors
    case invalidURL
    case weakSelf
    case socketError
    case emptyData
    case decodingError

    var localizedDescription: String {
        switch self {
        case .unauthorized:
            return "인증이 만료되었습니다. 다시 로그인해주세요."
        case .serverError(let error):
            return error.localizedDescription
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .weakSelf:
            return "메모리 참조 오류가 발생했습니다."
        case .socketError:
            return "소켓 연결 오류가 발생했습니다."
        case .emptyData:
            return "데이터가 비어있습니다."
        case .decodingError:
            return "데이터 파싱 오류가 발생했습니다."
        }
    }
}