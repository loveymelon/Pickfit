//
//  TokenRefreshCoordinatorTests.swift
//  PickfitTests
//
//  Created by 김진수 on 10/26/25.
//

import XCTest
@testable import Pickfit

/// TokenRefreshCoordinator의 Actor 기반 동시성 제어 테스트
///
/// 검증 항목:
/// 1. 단일 요청 시 정상 동작
/// 2. 동시 요청 시 1번만 갱신 실행
/// 3. 대기 요청 수 추적
/// 4. 에러 발생 시 모든 요청에 전파
/// 5. 순차 갱신 가능 여부
/// 6. 리프레쉬 토큰 만료(418) 시 처리
/// 7. Actor 직렬화 보장
final class TokenRefreshCoordinatorTests: XCTestCase {

    var coordinator: TokenRefreshCoordinator!

    override func setUp() {
        super.setUp()
        // Singleton 인스턴스 사용 (private init으로 인해 직접 생성 불가)
        coordinator = TokenRefreshCoordinator.shared
    }

    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }

    // MARK: - Test 1: 기본 동작 - 단일 요청 토큰 갱신

    /// 단일 요청 시 refreshLogic이 정상 실행되고 새 토큰을 반환하는지 검증
    func test_단일_요청_토큰_갱신_성공() async throws {
        // Given: 새 토큰을 반환하는 refreshLogic
        let expectedToken = "new_access_token_12345"

        // When: refresh 호출
        let result = try await coordinator.refresh {
            // 토큰 갱신 로직 시뮬레이션 (0.1초 소요)
            try await Task.sleep(nanoseconds: 100_000_000)
            return expectedToken
        }

        // Then: 새 토큰 반환
        XCTAssertEqual(result, expectedToken, "단일 요청 시 새 토큰이 반환되어야 함")
    }

    // MARK: - Test 2: 동시 요청 - 첫 번째만 갱신 실행

    /// 5개 동시 요청 시 refreshLogic이 1번만 실행되는지 검증
    func test_동시_5개_요청_시_1번만_갱신_실행() async throws {
        // Given: 갱신 호출 횟수 추적
        let refreshCallCount = ActorBox(value: 0)
        let expectedToken = "concurrent_token"

        // When: 5개 요청 동시 실행
        let results = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try await self.coordinator.refresh {
                        // refreshLogic 호출 횟수 증가
                        await refreshCallCount.increment()

                        // 토큰 갱신 시뮬레이션 (0.2초 소요)
                        try await Task.sleep(nanoseconds: 200_000_000)
                        return expectedToken
                    }
                }
            }

            // 모든 결과 수집
            var tokens: [String] = []
            for try await token in group {
                tokens.append(token)
            }
            return tokens
        }

        // Then: refreshLogic은 1번만 실행, 5개 요청 모두 같은 토큰 받음
        let callCount = await refreshCallCount.value
        XCTAssertEqual(callCount, 1, "5개 동시 요청이지만 refreshLogic은 1번만 실행되어야 함")
        XCTAssertEqual(results.count, 5, "5개 요청 모두 결과를 받아야 함")
        XCTAssertTrue(results.allSatisfy { $0 == expectedToken }, "모든 요청이 같은 토큰을 받아야 함")
    }

    // MARK: - Test 3: 대기 요청 수 확인

    /// 첫 번째 요청이 진행 중일 때 나머지 요청들이 대기 큐에 추가되는지 검증
    func test_대기_요청_수_확인() async throws {
        // Given: 장시간 소요되는 refreshLogic (0.5초)
        let expectedToken = "waiting_token"
        let startTime = Date()

        // When: 3개 요청 동시 실행
        let results = try await withThrowingTaskGroup(of: (token: String, duration: TimeInterval).self) { group in
            for index in 0..<3 {
                group.addTask {
                    let requestStart = Date()
                    let token = try await self.coordinator.refresh {
                        // 첫 번째 요청만 0.5초 소요
                        if Date().timeIntervalSince(startTime) < 0.1 {
                            try await Task.sleep(nanoseconds: 500_000_000)
                        }
                        return expectedToken
                    }
                    let duration = Date().timeIntervalSince(requestStart)
                    return (token: token, duration: duration)
                }
            }

            var results: [(String, TimeInterval)] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }

        // Then: 3개 요청 모두 성공, 첫 번째는 0.5초 소요, 나머지는 대기 후 즉시 반환
        XCTAssertEqual(results.count, 3, "3개 요청 모두 완료되어야 함")

        // 첫 번째 요청 (refreshLogic 실행)
        let durations = results.map { $0.1 }
        let maxDuration = durations.max()!
        XCTAssertGreaterThan(maxDuration, 0.4, "첫 번째 요청은 0.5초 소요")

        // 나머지 요청들 (대기 후 즉시 반환)
        let shortDurations = durations.filter { $0 < 0.6 && $0 < maxDuration }
        XCTAssertGreaterThanOrEqual(shortDurations.count, 2, "나머지 2개는 대기 큐에 있다가 반환")
        XCTAssertTrue(results.allSatisfy { $0.0 == expectedToken }, "모두 같은 토큰 받음")
    }

    // MARK: - Test 4: 에러 처리 - 모든 대기 요청에 에러 전달

    /// refreshLogic 에러 발생 시 모든 대기 중인 요청에 에러가 전달되는지 검증
    func test_에러_발생_시_모든_대기_요청에_전달() async throws {
        // Given: 에러를 던지는 refreshLogic
        struct RefreshError: Error, Equatable {
            let message: String
        }
        let expectedError = RefreshError(message: "Token refresh failed")

        // When: 4개 요청 동시 실행 (모두 실패해야 함)
        let results = await withTaskGroup(of: Result<String, Error>.self) { group in
            for _ in 0..<4 {
                group.addTask {
                    do {
                        let token = try await self.coordinator.refresh {
                            // 0.1초 후 에러 던짐
                            try await Task.sleep(nanoseconds: 100_000_000)
                            throw expectedError
                        }
                        return .success(token)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            var results: [Result<String, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Then: 4개 요청 모두 에러 받음
        XCTAssertEqual(results.count, 4, "4개 요청 모두 완료되어야 함")

        let errors = results.compactMap { result -> RefreshError? in
            if case .failure(let error) = result {
                return error as? RefreshError
            }
            return nil
        }

        XCTAssertEqual(errors.count, 4, "4개 요청 모두 에러를 받아야 함")
        XCTAssertTrue(errors.allSatisfy { $0 == expectedError }, "모두 같은 에러 받음")
    }

    // MARK: - Test 5: 순차 갱신 - 첫 번째 완료 후 두 번째 가능

    /// 첫 번째 갱신 완료 후 두 번째 갱신이 정상 실행되는지 검증
    func test_순차_갱신_가능() async throws {
        // Given: 첫 번째 토큰 갱신
        let firstToken = "first_token"
        let firstResult = try await coordinator.refresh {
            try await Task.sleep(nanoseconds: 100_000_000)
            return firstToken
        }

        XCTAssertEqual(firstResult, firstToken, "첫 번째 갱신 성공")

        // When: 두 번째 토큰 갱신 (첫 번째 완료 후)
        let secondToken = "second_token"
        let secondResult = try await coordinator.refresh {
            try await Task.sleep(nanoseconds: 100_000_000)
            return secondToken
        }

        // Then: 두 번째 갱신도 정상 동작
        XCTAssertEqual(secondResult, secondToken, "두 번째 갱신도 정상 실행됨")
        XCTAssertNotEqual(firstResult, secondResult, "각 갱신은 독립적으로 동작")
    }

    // MARK: - Test 6: 리프레쉬 토큰 만료 시 처리

    /// refreshLogic 내부에서 418 에러 발생 시 모든 대기 요청에 에러가 전달되는지 검증
    func test_리프레쉬_토큰_만료_시_모든_요청_실패() async throws {
        // Given: 418 에러를 던지는 refreshLogic
        struct RefreshTokenExpiredError: Error, Equatable {
            let statusCode: Int
            let message: String
        }
        let expectedError = RefreshTokenExpiredError(statusCode: 418, message: "Refresh token expired")

        // When: 3개 요청 동시 실행 (모두 418 에러로 실패해야 함)
        let results = await withTaskGroup(of: Result<String, Error>.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    do {
                        let token = try await self.coordinator.refresh {
                            // 418 에러 시뮬레이션
                            try await Task.sleep(nanoseconds: 100_000_000)
                            throw expectedError
                        }
                        return .success(token)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            var results: [Result<String, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Then: 3개 요청 모두 418 에러 받음
        XCTAssertEqual(results.count, 3, "3개 요청 모두 완료되어야 함")

        let errors = results.compactMap { result -> RefreshTokenExpiredError? in
            if case .failure(let error) = result {
                return error as? RefreshTokenExpiredError
            }
            return nil
        }

        XCTAssertEqual(errors.count, 3, "3개 요청 모두 418 에러를 받아야 함")
        XCTAssertTrue(errors.allSatisfy { $0.statusCode == 418 }, "모두 418 상태 코드")
        XCTAssertTrue(errors.allSatisfy { $0 == expectedError }, "모두 같은 에러 받음")
    }

    // MARK: - Test 7: Actor 직렬화 보장

    /// Actor가 isRefreshing 플래그에 대한 동시 접근을 직렬화하는지 검증
    func test_Actor_직렬화_보장_데이터_레이스_없음() async throws {
        // Given: 100개의 동시 요청 (극한 상황)
        let expectedToken = "race_test_token"
        let refreshCallCount = ActorBox(value: 0)

        // When: 100개 요청 동시 실행
        let results = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    try await self.coordinator.refresh {
                        // refreshLogic 호출 횟수 증가
                        await refreshCallCount.increment()

                        // 짧은 대기 (50ms)
                        try await Task.sleep(nanoseconds: 50_000_000)
                        return expectedToken
                    }
                }
            }

            var tokens: [String] = []
            for try await token in group {
                tokens.append(token)
            }
            return tokens
        }

        // Then: refreshLogic은 1번만 실행 (Actor가 직렬화 보장)
        let callCount = await refreshCallCount.value
        XCTAssertEqual(callCount, 1, "100개 동시 요청이지만 Actor가 직렬화하여 1번만 실행")
        XCTAssertEqual(results.count, 100, "100개 요청 모두 결과를 받아야 함")
        XCTAssertTrue(results.allSatisfy { $0 == expectedToken }, "모든 요청이 같은 토큰을 받아야 함")
    }
}

// MARK: - Test Helper: ActorBox

/// 테스트용 Actor (Int 값을 thread-safe하게 증가)
actor ActorBox<T> {
    var value: T

    init(value: T) {
        self.value = value
    }

    func increment() where T == Int {
        value += 1
    }
}
