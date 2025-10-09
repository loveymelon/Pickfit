//
//  ChatRouter.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation
import Alamofire

enum ChatRouter: Router {
    case fetchChatHistory(roomId: String, next: String?)
    case sendMessage(roomId: String, content: String, files: [String])
}

extension ChatRouter {
    var method: HTTPMethod {
        switch self {
        case .fetchChatHistory:
            return .get
        case .sendMessage:
            return .post
        }
    }

    var path: String {
        switch self {
        case .fetchChatHistory(let roomId, _):
            return "/chats/\(roomId)"
        case .sendMessage(let roomId, _, _):
            return "/chats/\(roomId)"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        return HTTPHeaders([
            HTTPHeader(name: "Content-Type", value: "application/json"),
            HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey)
        ])
    }

    var parameters: Parameters? {
        switch self {
        case .fetchChatHistory(_, let next):
            if let next = next {
                return ["next": next]
            }
            return nil

        case .sendMessage:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .fetchChatHistory:
            return nil

        case .sendMessage(_, let content, let files):
            let bodyDict: [String: Any] = [
                "content": content,
                "files": files
            ]
            return try? JSONSerialization.data(withJSONObject: bodyDict)
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .fetchChatHistory:
            return .url
        case .sendMessage:
            return .json
        }
    }
}
