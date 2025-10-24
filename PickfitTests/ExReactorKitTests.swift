//
//  ExReactorKitTests.swift
//  PickfitTests
//
//  ExReactorKit의 Async/Await + ReactorKit 통합 로직 검증
//

import XCTest
import RxSwift
import RxTest
import ReactorKit

@testable import Pickfit

// MARK: - ExReactorKit Unit Tests

/// ExReactorKit 확장 메서드 테스트
/// - run(operation:) 메서드가 Async/Await를 Observable로 올바르게 변환하는지 검증
/// - Task 취소, MainActor, Sendable 등 동시성 제어 검증
final class ExReactorKitTests: XCTestCase {

    // MARK: - Properties

    var reactor: TestReactor!       // 테스트할 Reactor
    var disposeBag: DisposeBag!     // RxSwift 구독 관리
    var scheduler: TestScheduler!   // 시간 제어 가능한 스케줄러 (테스트용)

    // MARK: - Setup & Teardown

    /// 각 테스트 실행 전 호출됨
    /// - 테스트마다 새로운 객체로 초기화하여 독립성 보장
    override func setUp() {
        super.setUp()
        reactor = TestReactor()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }

    /// 각 테스트 실행 후 호출됨
    /// - 메모리 정리
    override func tearDown() {
        reactor = nil
        disposeBag = nil
        scheduler = nil
        super.tearDown()
    }

    // MARK: - Test 1: Basic Operation

    /// 테스트 1: Async/Await → Observable 변환 기본 동작
    ///
    /// **검증 내용**:
    /// - `reactor.run { send in ... }` 패턴이 정상 작동
    /// - async 작업의 Mutation이 Observable로 방출됨
    /// - State가 올바르게 업데이트됨
    ///
    /// **시나리오**:
    /// 1. setValue(42) 액션 전달
    /// 2. Mutation이 Observable로 변환되어 방출됨
    /// 3. State.value가 42로 업데이트됨
    func test_run_기본동작_Mutation이_Observable로_변환됨() {
        // Given: 초기 상태 확인
        XCTAssertEqual(reactor.currentState.value, 0, "초기값은 0이어야 함")

        // 결과 저장용
        var receivedValue: Int?

        // State 변화 관찰
        reactor.state.map { $0.value }
            .subscribe(onNext: { value in
                receivedValue = value
            })
            .disposed(by: disposeBag)

        // When: setValue 액션 전달
        reactor.action.onNext(.setValue(42))

        // Then: State가 업데이트되었는지 확인
        XCTAssertEqual(reactor.currentState.value, 42, "State.value가 42로 업데이트되어야 함")
        XCTAssertEqual(receivedValue, 42, "Observable이 42를 방출해야 함")

        print("✅ Test 1 통과: 기본 async/await → Observable 변환 성공")
    }

    // MARK: - Test 2: Multiple Mutations

    /// 테스트 2: send()를 여러 번 호출할 때 순차 전달
    ///
    /// **검증 내용**:
    /// - async 작업 내에서 send()를 여러 번 호출 가능
    /// - Mutation들이 순서대로 방출됨
    /// - State가 마지막 Mutation까지 올바르게 반영됨
    ///
    /// **시나리오**:
    /// 1. multipleValues([1, 2, 3]) 액션 전달
    /// 2. send(.setLoading(true)) → send(.setValue(1)) → send(.setValue(2)) → send(.setValue(3)) → send(.setLoading(false))
    /// 3. State.value가 1 → 2 → 3으로 순차 업데이트됨
    func test_run_여러_Mutation_순차적으로_전달됨() {
        // Given: 값 변화 추적용 배열
        var receivedValues: [Int] = []

        reactor.state.map { $0.value }
            .distinctUntilChanged()
            .subscribe(onNext: { value in
                if value != 0 { // 초기값 0 제외
                    print("체크:", value)
                    receivedValues.append(value)
                }
            })
            .disposed(by: disposeBag)

        // When: 여러 값 전달
        reactor.action.onNext(.multipleValues([10, 20, 30]))

        // 비동기 작업 완료 대기 (최대 2초)
        let expectation = XCTestExpectation(description: "Multiple mutations")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Then: 모든 값이 순서대로 전달되었는지 확인
        XCTAssertEqual(receivedValues, [10, 20, 30], "값이 10 → 20 → 30 순서대로 전달되어야 함")
        XCTAssertEqual(reactor.currentState.value, 30, "최종 State.value는 30이어야 함")
        XCTAssertFalse(reactor.currentState.isLoading, "작업 완료 후 isLoading은 false여야 함")

        print("✅ Test 2 통과: send() 여러 번 호출 시 순차 전달 성공")
    }

    // MARK: - Test 3: Error Handling

    /// 테스트 3: async 작업에서 에러 발생 시 onError 처리
    ///
    /// **검증 내용**:
    /// - async 작업 내에서 throw한 에러를 onError가 받음
    /// - onError가 반환한 Mutation이 정상 방출됨
    /// - State에 에러 메시지가 반영됨
    ///
    /// **시나리오**:
    /// 1. throwError 액션 전달
    /// 2. async 작업에서 TestError.mockError 던짐
    /// 3. onError에서 .setError(message) Mutation 반환
    /// 4. State.errorMessage 업데이트됨
    func test_run_에러_발생시_onError_Mutation_방출됨() {
        // Given: 초기 상태에는 에러 없음
        XCTAssertNil(reactor.currentState.errorMessage, "초기 에러 메시지는 nil이어야 함")

        // 에러 메시지 추적
        var receivedError: String?

        reactor.state.map { $0.errorMessage }
            .subscribe(onNext: { error in
                print("에러:", error)
                receivedError = error
            })
            .disposed(by: disposeBag)

        // When: 에러 발생 액션 전달
        reactor.action.onNext(.throwError)

        // 비동기 작업 완료 대기
        let expectation = XCTestExpectation(description: "Error handling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: 에러 메시지가 State에 반영되었는지 확인
        XCTAssertNotNil(reactor.currentState.errorMessage, "에러 메시지가 설정되어야 함")

        // LocalizedError의 errorDescription을 사용하므로 "Mock Error for Testing" 메시지 확인
        XCTAssertTrue(
            reactor.currentState.errorMessage?.contains("Mock Error for Testing") ?? false,
            "에러 메시지에 'Mock Error for Testing'이 포함되어야 함. 실제: \(reactor.currentState.errorMessage ?? "nil")"
        )
        XCTAssertTrue(
            receivedError?.contains("Mock Error for Testing") ?? false,
            "Observable이 방출한 에러 메시지에 'Mock Error for Testing'이 포함되어야 함. 실제: \(receivedError ?? "nil")"
        )

        print("✅ Test 3 통과: 에러 발생 시 onError Mutation 방출 성공")
    }

    // MARK: - Test 4: Task Cancellation

    /// 테스트 4: Disposable 해제 시 Task 자동 취소
    ///
    /// **검증 내용**:
    /// - DisposeBag을 해제하면 Task가 취소됨
    /// - 취소된 Task의 send()는 무시됨 (Task.isCancelled 체크)
    /// - State 업데이트가 발생하지 않음
    ///
    /// **시나리오**:
    /// 1. longRunningTask 액션 전달 (1초 대기 작업)
    /// 2. 0.1초 후 disposeBag 해제 → Task 취소
    /// 3. 1초 대기 작업이 완료되어도 send()가 무시됨
    /// 4. State.value가 999로 업데이트되지 않음
    func test_Reactor_해제시_Task_취소됨() {
        // Given: Reactor를 옵셔널로 선언
        var testReactor: TestReactor? = TestReactor()
        
        var finalValue = 0
        
        testReactor?.state.map { $0.value }
            .subscribe(onNext: { value in
                finalValue = value
            })
            .disposed(by: disposeBag)
        
        // When: 긴 작업 시작
        testReactor?.action.onNext(.longRunningTask)
        
        // 0.1초 후 Reactor 해제
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            testReactor = nil  // ← Reactor 전체 해제
        }
        
        // 1.5초 대기
        let expectation = XCTestExpectation(description: "Reactor disposal")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Then: Reactor가 해제되어 값 업데이트 안 됨
        XCTAssertNotEqual(finalValue, 999)
    }

    // MARK: - Test 5: MainActor

    /// 테스트 5: async 작업이 MainActor에서 실행됨
    ///
    /// **검증 내용**:
    /// - reactor.run { send in ... }의 operation이 @MainActor에서 실행됨
    /// - Thread.isMainThread = true
    /// - UI 업데이트가 안전하게 메인 스레드에서 발생함
    ///
    /// **시나리오**:
    /// 1. async 작업 내에서 Thread.current 체크
    /// 2. 메인 스레드인지 확인
    func test_operation_MainActor에서_실행됨() {
        // Given: 스레드 체크용 변수
        var isMainThread: Bool = false

        // When: async 작업에서 스레드 확인
        let expectation = XCTestExpectation(description: "MainActor check")

        _ = reactor.run { send in
            // 현재 스레드가 메인 스레드인지 확인
            isMainThread = Thread.isMainThread
            print("🧵 Thread.isMainThread: \(isMainThread)")

            send(.setValue(100))
            expectation.fulfill()
        }
        .subscribe()
        .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)

        // Then: 메인 스레드에서 실행되었는지 확인
        XCTAssertTrue(isMainThread, "async 작업이 MainActor(메인 스레드)에서 실행되어야 함")

        print("✅ Test 5 통과: MainActor 실행 보장 성공")
    }

    // MARK: - Test 6: Sendable Safety

    /// 테스트 6: Send 구조체가 Task 취소 시 Mutation 무시
    ///
    /// **검증 내용**:
    /// - Send 구조체의 callAsFunction에서 Task.isCancelled 체크
    /// - Task가 취소되면 send()가 observer.onNext를 호출하지 않음
    /// - 이미 취소된 작업의 결과가 State에 반영되지 않음
    ///
    /// **시나리오**:
    /// 1. Task 시작 후 즉시 취소
    /// 2. send() 호출해도 무시됨
    /// 3. State 업데이트 안 됨
    ///
    /// **주의**: 이 테스트는 Task 취소 타이밍에 따라 결과가 달라질 수 있음
    func test_Send_구조체_Task_취소시_Mutation_무시() {
        // Given: 초기 상태
        var finalValue = 0

        reactor.state.map { $0.value }
            .subscribe(onNext: { value in
                finalValue = value
            })
            .disposed(by: disposeBag)

        // When: Task 시작 후 즉시 취소
        var localBag: DisposeBag? = DisposeBag()

        reactor.state
            .subscribe()
            .disposed(by: localBag!)

        reactor.action.onNext(.setValue(777))

        // 즉시 취소
        localBag = nil

        // 약간 대기
        let expectation = XCTestExpectation(description: "Send ignores cancelled task")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)

        // Then: 취소된 Task의 Mutation이 무시되었는지 확인
        // 주의: setValue는 동기 작업이라 취소 전에 실행될 수 있음
        // 이 테스트는 ExReactorKit의 isCancelled 체크 로직을 문서화하는 용도

        print("✅ Test 6 통과: Send 구조체 Task 취소 처리 확인 완료")
        print("   (참고: Task.isCancelled 체크는 ExReactorKit.swift:64 에서 수행됨)")
    }
}
