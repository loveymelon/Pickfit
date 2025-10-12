//
//  MyPageReactor.swift
//  Pickfit
//
//  Created by Claude on 10/12/25.
//

import Foundation
import ReactorKit
import RxSwift

final class MyPageReactor: Reactor {

    enum Action {
        case viewDidLoad
        case logoutButtonTapped
    }

    enum Mutation {
        case setUserInfo(nickname: String, email: String?)
        case setLoading(Bool)
        case setLogoutSuccess
        case setError(String)
    }

    struct State {
        var nickname: String = ""
        var email: String?
        var isLoading: Bool = false
        var isLogoutSuccess: Bool = false
        var errorMessage: String?
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            print("📱 [MyPageReactor] viewDidLoad")
            return fetchUserInfo()

        case .logoutButtonTapped:
            print("🚪 [MyPageReactor] logoutButtonTapped - 로그아웃 시작")
            return logout()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setUserInfo(let nickname, let email):
            print("👤 [MyPageReactor] setUserInfo - \(nickname)")
            newState.nickname = nickname
            newState.email = email

        case .setLoading(let isLoading):
            print("⏳ [MyPageReactor] setLoading - \(isLoading)")
            newState.isLoading = isLoading
            newState.errorMessage = nil

        case .setLogoutSuccess:
            print("✅ [MyPageReactor] setLogoutSuccess")
            newState.isLoading = false
            newState.isLogoutSuccess = true

        case .setError(let message):
            print("❌ [MyPageReactor] setError - \(message)")
            newState.isLoading = false
            newState.errorMessage = message
        }

        return newState
    }

    // MARK: - Private Methods

    private func fetchUserInfo() -> Observable<Mutation> {
        // KeychainAuthStorage에서 사용자 정보 가져오기
        let userId = KeychainAuthStorage.shared.readUserIdSync() ?? "알 수 없음"

        // TODO: 실제로는 서버에서 사용자 정보를 가져와야 함
        // 현재는 userId만 표시
        return .just(.setUserInfo(nickname: userId, email: nil))
    }

    private func logout() -> Observable<Mutation> {
        return run(
            operation: { send in
                send(.setLoading(true))

                // 1. 토큰 삭제
                await KeychainAuthStorage.shared.clear()

                // 2. 장바구니 비우기
                CartManager.shared.clearCart()

                print("✅ [MyPage] 로그아웃 성공")
                send(.setLogoutSuccess)
            },
            onError: { error in
                .setError(error.localizedDescription)
            }
        )
    }
}
