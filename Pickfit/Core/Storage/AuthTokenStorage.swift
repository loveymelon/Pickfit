//
//  AuthTokenStorage.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation
import KeychainSwift

protocol AuthTokenStorage {
    func readAccess() -> String?
    func readRefresh() -> String?
    func readUserId() -> String?
    func write(access: String, refresh: String?)
    func writeUserId(_ userId: String)
    func clear()
}

@propertyWrapper
struct KeychainValue {
    let key: KeyChainKeys

    var wrappedValue: String? {
        get {
            KeychainSwift().get(key.rawValue)
        }

        set {
            let keychain = KeychainSwift()

            if let value = newValue {
                keychain.set(value, forKey: key.rawValue)
            } else {
                keychain.delete(key.rawValue)
            }
        }
    }
}

enum KeyChainKeys: String {
    case userId
    case accessToken
    case refreshToken
}

final class KeychainAuthStorage: AuthTokenStorage {
    static let shared = KeychainAuthStorage()

    private let keychain = KeychainSwift()

    private init() {}

    func readAccess() -> String? {
        let token = keychain.get(KeyChainKeys.accessToken.rawValue)

        print("token", token)
        return token
    }

    func readRefresh() -> String? {
        keychain.get(KeyChainKeys.refreshToken.rawValue)
    }

    func readUserId() -> String? {
        keychain.get(KeyChainKeys.userId.rawValue)
    }

    func write(access: String, refresh: String?) {
        keychain.set(access, forKey: KeyChainKeys.accessToken.rawValue)

        if let r = refresh {
            keychain.set(r, forKey: KeyChainKeys.refreshToken.rawValue)
        }
    }

    func writeUserId(_ userId: String) {
        keychain.set(userId, forKey: KeyChainKeys.userId.rawValue)
    }

    func clear() {
        keychain.delete(KeyChainKeys.accessToken.rawValue)
        keychain.delete(KeyChainKeys.refreshToken.rawValue)
        keychain.delete(KeyChainKeys.userId.rawValue)
    }
}
