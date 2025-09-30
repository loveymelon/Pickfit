//
//  NetworkManager.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Alamofire
import Foundation

actor NetworkManager {
    private let interceptor: RequestInterceptor?

    init(interceptor: RequestInterceptor? = nil) {
        self.interceptor = interceptor
    }

    func fetch<T: DTO, R: Router>(dto: T.Type, router: R) async throws -> T {
        let request = try router.asURLRequest()

        let response = await getResponse(dto: dto, request: request)

        let result = try getResult(dto: dto, response: response)

        return result
    }
}

extension NetworkManager {
    private func getResponse<T: DTO>(dto: T.Type, request: URLRequest) async -> DataResponse<T, AFError> {
        if let interceptor = interceptor {
            return await AF.request(request, interceptor: interceptor)
                .validate(statusCode: 200..<300)
                .serializingDecodable(T.self)
                .response
        } else {
            return await AF.request(request)
                .validate(statusCode: 200..<300)
                .serializingDecodable(T.self)
                .response
        }
    }

    private func getResult<T: DTO>(dto: T.Type, response: DataResponse<T, AFError>) throws -> T {
        switch response.result {
        case let .success(data):
            print("success", data)
            return data

        case let .failure(error):
            print("error", error.localizedDescription)
            throw error
        }
    }
}
