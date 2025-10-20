//
//  NetworkManager.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Alamofire
import Foundation

actor NetworkManager {
    static let shared: NetworkManager = NetworkManager(hasInterceptor: true)
    static let auth: NetworkManager = NetworkManager(hasInterceptor: false)

    private let interceptor: AuthInterceptor?

    private init(hasInterceptor: Bool) {
        self.interceptor = hasInterceptor ? AuthInterceptor() : nil
    }

    func fetch<T: DTO, R: Router>(dto: T.Type, router: R) async throws -> T {
        let request = try router.asURLRequest()
        let hasAuth = interceptor != nil

        print("📡 [Network] Starting request")
        print("   🌐 URL: \(request.url?.absoluteString ?? "nil")")
        print("   📋 Method: \(request.httpMethod ?? "nil")")
        print("   🔐 Has Interceptor: \(hasAuth)")
        print("   📋 Headers: \(request.allHTTPHeaderFields ?? [:])")

        let response = await getResponse(dto: dto, request: request)

        let result = try getResult(dto: dto, response: response)

        print("✅ [Network] Request successful")
        print("   🌐 URL: \(request.url?.path ?? "nil")")

        return result
    }

    /// 빈 응답을 허용하는 요청 (200 OK만 확인, 응답 파싱 안 함)
    /// - Note: 서버가 응답 본문 없이 200 OK만 보내는 경우 사용
    func fetchWithoutResponse<R: Router>(router: R) async throws {
        let request = try router.asURLRequest()
        let hasAuth = interceptor != nil

        print("📡 [Network] Starting request (no response expected)")
        print("   🌐 URL: \(request.url?.absoluteString ?? "nil")")
        print("   📋 Method: \(request.httpMethod ?? "nil")")
        print("   🔐 Has Interceptor: \(hasAuth)")

        let emptyCodes: Set<Int> = [200, 201, 204, 205]
        let serializer = DataResponseSerializer(emptyResponseCodes: emptyCodes)

        let req = AF.request(request, interceptor: interceptor)
            .validate(statusCode: 200..<300)   // 두 분기 모두 검증 통일

        let response = await req
            .serializingResponse(using: serializer)
            .response

        switch response.result {
        case .success:
            print("✅ [Network] Request successful (no response body)")
            print("   🌐 URL: \(request.url?.path ?? "nil")")
        case let .failure(error):
            print("❌ [Network Error] Request failed")
            print("   🌐 URL: \(response.request?.url?.absoluteString ?? "nil")")
            print("   📊 AFError: \(error)")

            if let statusCode = response.response?.statusCode {
                print("   📊 Status Code: \(statusCode)")
                if [401, 403, 418].contains(statusCode) {
                    throw NetworkError.unauthorized
                }
            }
            throw NetworkError.serverError(error)
        }
    }

    /// Multipart/form-data 업로드 (파일 업로드용)
    func uploadMultipart<T: DTO, R: Router>(dto: T.Type, router: R) async throws -> T {
        let request = try router.asURLRequest()
        let hasAuth = interceptor != nil

        print("📡 [Network] Starting multipart upload")
        print("   🌐 URL: \(request.url?.absoluteString ?? "nil")")
        print("   📋 Method: \(request.httpMethod ?? "nil")")
        print("   🔐 Has Interceptor: \(hasAuth)")

        // EncodingType에서 MultipartFormData 추출
        guard case .multiPart(let formData) = router.encodingType else {
            print("❌ [Network] Router encodingType is not multiPart")
            throw NetworkError.invalidURL
        }

        let response = await getMultipartResponse(dto: dto, request: request, formData: formData)

        let result = try getResult(dto: dto, response: response)

        print("✅ [Network] Multipart upload successful")
        print("   🌐 URL: \(request.url?.path ?? "nil")")

        return result
    }
}

extension NetworkManager {
    private func getResponse<T: DTO>(dto: T.Type, request: URLRequest) async -> DataResponse<T, AFError> {
        if let interceptor = interceptor {
            return await AF.request(request, interceptor: interceptor)
                .serializingDecodable(T.self)
                .response
        } else {
            return await AF.request(request)
                .validate(statusCode: 200..<300)
                .serializingDecodable(T.self)
                .response
        }
    }

    private func getMultipartResponse<T: DTO>(dto: T.Type, request: URLRequest, formData: MultipartFormData) async -> DataResponse<T, AFError> {
        if let interceptor = interceptor {
            return await AF.upload(multipartFormData: formData, with: request, interceptor: interceptor)
                .serializingDecodable(T.self)
                .response
        } else {
            return await AF.upload(multipartFormData: formData, with: request)
                .validate(statusCode: 200..<300)
                .serializingDecodable(T.self)
                .response
        }
    }

    private func getResult<T: DTO>(dto: T.Type, response: DataResponse<T, AFError>) throws -> T {
        switch response.result {
        case let .success(data):
            return data

        case let .failure(error):
            print("❌ [Network Error] Request failed")
            print("   🌐 URL: \(response.request?.url?.absoluteString ?? "nil")")
            print("   📊 AFError: \(error)")

            // 401, 418 에러는 NetworkError.unauthorized로 변환
            if let statusCode = response.response?.statusCode {
                print("   📊 Status Code: \(statusCode)")
                if let data = response.data, let errorMessage = String(data: data, encoding: .utf8) {
                    print("   📄 Error response body: \(errorMessage)")
                }

                if statusCode == 401 || statusCode == 403 || statusCode == 418 {
                    print("   ⚠️ Auth error - Throwing NetworkError.unauthorized")
                    throw NetworkError.unauthorized
                }
            } else {
                print("   ⚠️ No HTTP status code")
                print("   📄 Error description: \(error.localizedDescription)")
            }

            print("   ⚠️ Throwing NetworkError.serverError")
            throw NetworkError.serverError(error)
        }
    }
}
