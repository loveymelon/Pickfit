//
//  SignUpReactor.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import Foundation
import ReactorKit
import RxSwift

final class SignUpReactor: Reactor {

    private let authRepository: AuthRepository
    private let notificationRepository: NotificationRepository

    init(
        authRepository: AuthRepository = AuthRepository(),
        notificationRepository: NotificationRepository = NotificationRepository()
    ) {
        self.authRepository = authRepository
        self.notificationRepository = notificationRepository
    }

    enum Action {
        case emailChanged(String)
        case validateEmailButtonTapped
        case passwordChanged(String)
        case passwordConfirmChanged(String)
        case nickChanged(String)
        case phoneNumChanged(String)
        case signUpButtonTapped
    }

    enum Mutation {
        case setEmail(String)
        case setEmailValidation(Bool, String?)
        case setPassword(String)
        case setPasswordConfirm(String)
        case setNick(String)
        case setPhoneNum(String)
        case setLoading(Bool)
        case setSignUpSuccess
        case setError(String)
    }

    struct State {
        var email: String = ""
        var isEmailValid: Bool = false
        var emailValidationMessage: String? = nil
        var password: String = ""
        var passwordConfirm: String = ""
        var nick: String = ""
        var phoneNum: String = ""
        var isLoading: Bool = false
        var isSignUpSucceed: Bool = false
        var errorMessage: String? = nil

        var isFormValid: Bool {
            return isEmailValid &&
                   !password.isEmpty &&
                   !passwordConfirm.isEmpty &&
                   password == passwordConfirm &&
                   !nick.isEmpty &&
                   !phoneNum.isEmpty
        }
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .emailChanged(let email):
            return Observable.just(.setEmail(email))

        case .validateEmailButtonTapped:
            let currentEmail = currentState.email

            guard !currentEmail.isEmpty else {
                return Observable.just(.setEmailValidation(false, "이메일을 입력해주세요."))
            }

            guard isValidEmailFormat(currentEmail) else {
                return Observable.just(.setEmailValidation(false, "유효하지 않은 이메일 형식입니다."))
            }

            return run(
                operation: { [weak self] send in
                    guard let self else { return }
                    send(.setLoading(true))

                    let message = try await self.authRepository.validateEmail(currentEmail)
                    send(.setEmailValidation(true, message))
                    send(.setLoading(false))
                },
                onError: { error in
                    return .setError("이미 사용 중인 이메일입니다.")
                }
            ).flatMap { mutation -> Observable<Mutation> in
                if case .setError = mutation {
                    return Observable.concat([
                        .just(.setEmailValidation(false, "이미 사용 중인 이메일입니다.")),
                        .just(.setLoading(false))
                    ])
                }
                return .just(mutation)
            }

        case .passwordChanged(let password):
            return Observable.just(.setPassword(password))

        case .passwordConfirmChanged(let passwordConfirm):
            return Observable.just(.setPasswordConfirm(passwordConfirm))

        case .nickChanged(let nick):
            return Observable.just(.setNick(nick))

        case .phoneNumChanged(let phoneNum):
            return Observable.just(.setPhoneNum(phoneNum))

        case .signUpButtonTapped:
            return run(
                operation: { [weak self] send in
                    guard let self else { return }
                    let state = self.currentState

                    send(.setLoading(true))

                    // 유효성 검사
                    guard state.isEmailValid else {
                        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "이메일 중복 확인을 해주세요."])
                    }

                    guard state.password == state.passwordConfirm else {
                        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "비밀번호가 일치하지 않습니다."])
                    }

                    guard self.isValidPassword(state.password) else {
                        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "비밀번호는 8자 이상, 영문/숫자/특수문자를 포함해야 합니다."])
                    }

                    // 회원가입 API
                    try await self.authRepository.signUp(
                        email: state.email,
                        password: state.password,
                        nick: state.nick,
                        phoneNum: state.phoneNum
                    )

                    // FCM 토큰 업데이트
                    try await self.updateFCMTokenIfNeeded()

                    send(.setSignUpSuccess)
                    send(.setLoading(false))
                },
                onError: { error in
                    return .setError(error.localizedDescription)
                }
            ).flatMap { mutation -> Observable<Mutation> in
                if case .setError = mutation {
                    return Observable.concat([
                        .just(mutation),
                        .just(.setLoading(false))
                    ])
                }
                return .just(mutation)
            }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setEmail(let email):
            newState.email = email
            newState.isEmailValid = false  // 이메일 변경 시 검증 초기화
            newState.emailValidationMessage = nil

        case .setEmailValidation(let isValid, let message):
            newState.isEmailValid = isValid
            newState.emailValidationMessage = message

        case .setPassword(let password):
            newState.password = password
            newState.errorMessage = nil

        case .setPasswordConfirm(let passwordConfirm):
            newState.passwordConfirm = passwordConfirm
            newState.errorMessage = nil

        case .setNick(let nick):
            newState.nick = nick

        case .setPhoneNum(let phoneNum):
            newState.phoneNum = phoneNum

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setSignUpSuccess:
            newState.isSignUpSucceed = true
            newState.errorMessage = nil

        case .setError(let error):
            newState.errorMessage = error
            newState.isLoading = false
        }

        return newState
    }

    // MARK: - Private Methods

    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        // 8자 이상, 영문/숫자/특수문자 포함
        guard password.count >= 8 else { return false }

        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[@$!%*#?&]", options: .regularExpression) != nil

        return hasLetter && hasNumber && hasSpecial
    }

    private func updateFCMTokenIfNeeded() async throws {
        guard let fcmToken = await getFCMToken() else {
            print("⚠️ [SignUpReactor] FCM Token not available")
            return
        }

        let cachedToken = UserDefaults.standard.string(forKey: "deviceToken")

        if fcmToken != cachedToken {
            print("🔄 [SignUpReactor] Updating FCM Token to server")
            try await notificationRepository.updateDeviceToken(fcmToken)
            UserDefaults.standard.set(fcmToken, forKey: "deviceToken")
        } else {
            print("ℹ️ [SignUpReactor] FCM Token already up to date")
        }
    }

    @MainActor
    private func getFCMToken() async -> String? {
        return await withCheckedContinuation { continuation in
            #if canImport(FirebaseMessaging)
            // FirebaseMessaging이 있으면 토큰 가져오기
            continuation.resume(returning: UserDefaults.standard.string(forKey: "deviceToken"))
            #else
            continuation.resume(returning: nil)
            #endif
        }
    }
}
