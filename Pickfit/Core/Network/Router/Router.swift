//
//  Router.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Alamofire

protocol Router {
    var method: HTTPMethod { get }
    var baseURL: String { get }
    var path: String { get }
    var optionalHeaders: HTTPHeaders? { get }
    var headers: HTTPHeaders { get }
    var parameters: Parameters? { get }
    var body: Data? { get }
    var encodingType: EncodingType { get }
}

extension Router {
    var baseURL: String {
        return APIKey.baseURL
    }

    var headers: HTTPHeaders {
        var combine = HTTPHeaders()
        if let optionalHeaders {
            optionalHeaders.forEach { header in
                combine.add(header)
            }
        }
        return combine
    }

    func asURLRequest() throws(Error) -> URLRequest {
        let url = try baseURLToURL()

        var urlRequest = try urlToURLRequest(url: url)

        switch encodingType {
        case .url:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            return urlRequest

        case .json:
            let jsonObject = JSONCoder.toJSONSerialization(data: body)
            urlRequest = try JSONEncoding.default.encode(urlRequest, withJSONObject: jsonObject)
            return urlRequest

        case .multiPart:
            // TODO: MultiPart encoding implementation
            return urlRequest
        }
    }

    private func baseURLToURL() throws(Error) -> URL {
        do {
            let url = try baseURL.asURL()
            return url
        } catch let error as AFError {
            switch error {
            case .invalidURL:
                throw error
            case .parameterEncodingFailed, .multipartEncodingFailed:
                throw error
            default:
                throw error
            }
        } catch {
            throw error
        }
    }

    private func urlToURLRequest(url: URL) throws(Error) -> URLRequest {
        do {
            let urlRequest = try URLRequest(url: url.appending(path: path), method: method, headers: headers)
            return urlRequest
        } catch let error as AFError {
            switch error {
            case .invalidURL:
                throw error
            case .parameterEncodingFailed:
                throw error
            default:
                throw error
            }
        } catch {
            throw error
        }
    }

    func requestToBody(_ request: Encodable) -> Data? {
        do {
            return try JSONCoder.encode(request)
        } catch {
            #if DEBUG
            print("requestToBody Error")
            #endif
            return nil
        }
    }
}