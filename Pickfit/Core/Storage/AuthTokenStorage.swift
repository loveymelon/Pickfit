//
//  AuthTokenStorage.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation
import KeychainSwift

protocol AuthTokenStorage {
    func readAccess() async -> String?
    func readRefresh() async -> String?
    func write(access: String, refresh: String?) async
    func clear() async
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

actor KeychainAuthStorage: AuthTokenStorage {
    static let shared = KeychainAuthStorage()

    private let keychain = KeychainSwift()

    private init() {}

    func readAccess() async -> String? {
        let token = keychain.get(KeyChainKeys.accessToken.rawValue)
        
        print("token", token)
        return token
    }

    func readRefresh() async -> String? {
        keychain.get(KeyChainKeys.refreshToken.rawValue)
    }

    func write(access: String, refresh: String?) async {
        keychain.set(access, forKey: KeyChainKeys.accessToken.rawValue)

        if let r = refresh {
            keychain.set(r, forKey: KeyChainKeys.refreshToken.rawValue)
        }
    }

    func clear() async {
        keychain.delete(KeyChainKeys.accessToken.rawValue)
        keychain.delete(KeyChainKeys.refreshToken.rawValue)
    }
}
