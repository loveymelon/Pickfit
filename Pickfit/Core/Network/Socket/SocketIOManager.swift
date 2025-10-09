//
//  SocketIOManager.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import UIKit
import SocketIO

final class SocketIOManager {

    static let shared = SocketIOManager()
    private var manager: SocketManager?
    private var socket: SocketIOClient?

    private init() {
        setup()
    }

    func startSocket() {
        print("소켓 시도 시작")
        socket?.connect()
    }

    func stopAndRemoveSocket() {
        stopSocket()
        removeSocket()
    }

    func stopSocket() {
        print("소켓 멈춥니다.")
        socket?.disconnect()
    }

    func removeSocket() {
        print("소켓 완전 제거")
        if let socket {
            manager?.removeSocket(socket)
        }
        socket = nil
        manager = nil
    }

    func sendMessage(event: String, data: [String: Any]) {
        guard socket?.status == .connected else {
            print("⚠️ 소켓이 연결되지 않음 - 메시지 전송 실패")
            return
        }

        print("📤 소켓 메시지 전송: \(event)")
        print("📦 데이터: \(data)")
        socket?.emit(event, data)
    }

    deinit {
        print("소켓 디이닛 (나올수 없는 상황)")
    }
}

// MARK: - Connection
extension SocketIOManager {

    func connectDTO<T: DTO>(to socketCase: SocketCase, type: T.Type) -> AsyncStream<Result<T, NetworkError>> {
        let base = APIKey.baseURL
        guard let url = URL(string: base) else {
            print("유효하지 않은 소켓 URL")
            return AsyncStream { continuation in
                continuation.yield(.failure(.invalidURL))
                continuation.finish()
            }
        }
        print("소켓 요청 URL: " + url.absoluteString)

        // 토큰 가져오기 (동기 방식)
        let token = KeychainAuthStorage.shared.readAccessSync() ?? ""

        let config: SocketIOClientConfiguration = [
            .log(false), // 프로덕션에서는 false
            .compress,
            .reconnects(true),
            .reconnectWait(5),
            .reconnectAttempts(-1),
            .forceNew(true),
            .secure(false),
            .connectParams(["token": token]) // 토큰 전달
        ]

        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.socket(forNamespace: socketCase.address)

        return AsyncStream { [weak self] continuation in
            guard let self else {
                print("소켓에 Weak Self Error")
                continuation.yield(.failure(.weakSelf))
                continuation.finish()
                return
            }

            print("소켓 AsyncStream Start")
            self.setupSocketHandlers(continuation: continuation, type: type, eventName: socketCase.eventName)
            socket?.connect()

            continuation.onTermination = { @Sendable _ in
                print("소켓 생성자 다이")
                self.stopSocket()
            }
        }
    }

    private func setupSocketHandlers<T: DTO>(
        continuation: AsyncStream<Result<T, NetworkError>>.Continuation,
        type: T.Type,
        eventName: String
    ) {
        socket?.on(clientEvent: .connect) { data, ack in
            print("✅ 소켓 연결 성공")
            print("Data: \(data), Ack: \(ack)")
        }

        socket?.on(clientEvent: .disconnect) { data, ack in
            print("❌ 소켓 연결 종료")
            print("Data: \(data), Ack: \(ack)")
        }

        socket?.on(clientEvent: .error) { data, ack in
            print("⚠️ 소켓 에러 발생: \(data)")
            continuation.yield(.failure(.socketError))
            self.stopAndRemoveSocket()
            continuation.finish()
        }

        socket?.on(clientEvent: .reconnect) { data, ack in
            print("🔄 소켓 재연결 중...")
        }

        socket?.on(clientEvent: .reconnectAttempt) { data, ack in
            print("🔄 소켓 재연결 시도 중...")
        }

        socket?.on(eventName) { dataArray, ack in
            print("📨 소켓 메시지 수신: \(eventName)")
            do {
                guard let dataFirst = dataArray.first else {
                    print("⚠️ 소켓 데이터가 비어있음")
                    continuation.yield(.failure(.emptyData))
                    return
                }

                print("🔄 JSON 직렬화 시도...")
                let jsonData = try JSONSerialization.data(withJSONObject: dataFirst, options: [])

                print("🔄 JSON 디코딩 시도...")
                let dto = try JSONCoder.decode(T.self, from: jsonData)

                print("✅ 소켓 데이터 방출 성공")
                continuation.yield(.success(dto))

            } catch {
                print("❌ 소켓 파싱 에러: \(error)")
                continuation.yield(.failure(.decodingError))
            }
        }
    }
}

// MARK: - Lifecycle Management
extension SocketIOManager {
    private func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(suspendSocket),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restartSocket),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc
    private func suspendSocket() {
        print("📱 앱 백그라운드 진입 - 소켓 일시정지")
        stopSocket()
    }

    @objc
    private func restartSocket() {
        print("📱 앱 포그라운드 진입 - 소켓 재시작")
        startSocket()
    }
}

