//
//  SocketCase.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import Foundation

enum SocketCase {
    case chat(roomId: String)

    /// Socket.IO 네임스페이스 (각 채팅방마다 별도 네임스페이스)
    var namespace: String {
        switch self {
        case .chat(let roomId):
            return "/chats-\(roomId)"
        }
    }

    /// 메시지 수신/전송에 사용할 이벤트 이름
    var eventName: String {
        switch self {
        case .chat:
            return "chat"
        }
    }
}
