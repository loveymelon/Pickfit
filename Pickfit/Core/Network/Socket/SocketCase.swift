//
//  SocketCase.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import Foundation

enum SocketCase {
    case chat(roomId: String)

    var address: String {
        switch self {
        case .chat(let roomId):
            return "/chat/\(roomId)"
        }
    }

    var eventName: String {
        switch self {
        case .chat:
            return "message"
        }
    }
}
