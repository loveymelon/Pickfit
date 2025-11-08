//
//  ChatRouter.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import Foundation
import Alamofire

enum ChatRouter: Router {
    case fetchChatRoomList
    case createChatRoom(opponentId: String)  // 채팅방 생성/조회
    case fetchChatHistory(roomId: String, next: String?)
    case sendMessage(roomId: String, content: String, files: [String])
    case uploadFiles(roomId: String, fileDataList: [(data: Data, fileName: String, isPDF: Bool)])  // 파일 업로드 (multipart/form-data)
}

extension ChatRouter {
    var method: HTTPMethod {
        switch self {
        case .fetchChatRoomList:
            return .get
        case .createChatRoom:
            return .post
        case .fetchChatHistory:
            return .get
        case .sendMessage:
            return .post
        case .uploadFiles:
            return .post
        }
    }

    var path: String {
        switch self {
        case .fetchChatRoomList:
            return "/chats"
        case .createChatRoom:
            return "/chats"
        case .fetchChatHistory(let roomId, _):
            return "/chats/\(roomId)"
        case .sendMessage(let roomId, _, _):
            return "/chats/\(roomId)"
        case .uploadFiles(let roomId, _):
            return "/chats/\(roomId)/files"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        switch self {
        case .uploadFiles:
            // multipart/form-data는 Alamofire가 자동으로 Content-Type 설정
            return HTTPHeaders([
                HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey)
            ])
        default:
            return HTTPHeaders([
                HTTPHeader(name: "Content-Type", value: "application/json"),
                HTTPHeader(name: "SeSACKey", value: APIKey.sesacKey)
            ])
        }
    }

    var parameters: Parameters? {
        switch self {
        case .fetchChatRoomList:
            return nil

        case .createChatRoom:
            return nil

        case .fetchChatHistory(_, let next):
            if let next = next {
                return ["next": next]
            }
            return nil

        case .sendMessage:
            return nil

        case .uploadFiles:
            return nil  // multipart/form-data는 parameters 사용 안 함
        }
    }

    var body: Data? {
        switch self {
        case .fetchChatRoomList:
            return nil

        case .createChatRoom(let opponentId):
            let bodyDict: [String: Any] = [
                "opponent_id": opponentId
            ]
            return try? JSONSerialization.data(withJSONObject: bodyDict)

        case .fetchChatHistory:
            return nil

        case .sendMessage(_, let content, let files):
            let bodyDict: [String: Any] = [
                "content": content,
                "files": files
            ]
            return try? JSONSerialization.data(withJSONObject: bodyDict)

        case .uploadFiles:
            return nil  // multipart/form-data는 body 사용 안 함
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .fetchChatRoomList:
            return .url
        case .createChatRoom:
            return .json
        case .fetchChatHistory:
            return .url
        case .sendMessage:
            return .json
        case .uploadFiles(_, let fileDataList):
            // MultipartFormData 구성
            let formData = MultipartFormData()
            for (index, fileInfo) in fileDataList.enumerated() {
                let fileName: String
                let mimeType: String

                if fileInfo.isPDF {
                    // PDF 파일
                    fileName = fileInfo.fileName.isEmpty ? "file_\(Date().timeIntervalSince1970)_\(index).pdf" : fileInfo.fileName
                    mimeType = "application/pdf"
                } else {
                    // 이미지 파일
                    fileName = "image_\(Date().timeIntervalSince1970)_\(index).jpg"
                    mimeType = "image/jpeg"
                }

                formData.append(
                    fileInfo.data,
                    withName: "files",
                    fileName: fileName,
                    mimeType: mimeType
                )

                print("📤 [ChatRouter] Appending file: \(fileName), mimeType: \(mimeType)")
            }
            return .multiPart(formData)
        }
    }
}
