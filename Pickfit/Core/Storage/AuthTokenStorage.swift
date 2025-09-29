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
    @KeychainValue(key: .accessToken)
    private var accessToken: String?

    @KeychainValue(key: .refreshToken)
    private var refreshToken: String?

    func readAccess() async -> String? {
        accessToken
    }

    func readRefresh() async -> String? {
        refreshToken
    }

    func write(access: String, refresh: String?) async {
        accessToken = access

        if let r = refresh {
            refreshToken = r
        }
    }

    func clear() async {
        accessToken = nil
        refreshToken = nil
    }
}