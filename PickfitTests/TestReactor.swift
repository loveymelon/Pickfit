//
//  TestReactor.swift
//  PickfitTests
//
//  Created for ExReactorKit Unit Testing
//

import ReactorKit
import RxSwift
import Foundation

// MARK: - 테스트용 Mock Reactor

/// ExReactorKit 테스트 전용 간단한 Reactor
/// 실제 앱 로직 없이 순수하게 ExReactorKit의 동작만 테스트하기 위한 Mock
final class TestReactor: Reactor {

    // MARK: - Action (사용자 입력)

    enum Action {
        case setValue(Int)              // 값 설정 액션
        case throwError                 // 에러 발생 액션
        case multipleValues([Int])      // 여러 값 전달 액션
        case longRunningTask            // 긴 작업 (취소 테스트용)
    }

    // MARK: - Mutation (상태 변경 명령)

    enum Mutation {
        case setValue(Int)              // 값 변경
        case setError(String)           // 에러 메시지 설정
        case setLoading(Bool)           // 로딩 상태 변경
    }

    // MARK: - State (화면에 표시될 상태)

    struct State {
        var value: Int = 0              // 현재 값
        var errorMessage: String? = nil // 에러 메시지
        var isLoading: Bool = false     // 로딩 중 여부
    }

    let initialState = State()

    // MARK: - Mutate (Action을 Mutation으로 변환)

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        // 1. 단순 값 설정 (동기 작업)
        case .setValue(let value):
            return .just(.setValue(value))

        // 2. 에러 발생 (ExReactorKit의 onError 테스트용)
        case .throwError:
            return run(
                operation: { send in
                    // 의도적으로 에러 던짐
                    throw TestError.mockError
                },
                onError: { error in
                    // 에러를 Mutation으로 변환
                    return .setError(error.localizedDescription)
                }
            )

        // 3. 여러 Mutation 순차 전달 (send 여러 번 호출 테스트)
        case .multipleValues(let values):
            return run { send in
                send(.setLoading(true))
                
                for value in values {
                    send(.setValue(value))
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms 딜레이
                }

                send(.setLoading(false))
            }

        // 4. 긴 작업 (Task 취소 테스트용)
        case .longRunningTask:
            return run { send in
                send(.setLoading(true))

                // 1초 대기 (취소될 수 있음)
                try? await Task.sleep(nanoseconds: 1_000_000_000)

                send(.setValue(999))
                send(.setLoading(false))
            }
        }
    }

    // MARK: - Reduce (Mutation을 받아서 State 업데이트)

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setValue(let value):
            newState.value = value

        case .setError(let message):
            newState.errorMessage = message

        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}

// MARK: - 테스트용 에러

enum TestError: Error, LocalizedError {
    case mockError

    // LocalizedError 프로토콜 구현 (이게 실제로 사용됨!)
    var errorDescription: String? {
        switch self {
        case .mockError:
            return "Mock Error for Testing"
        }
    }
}
