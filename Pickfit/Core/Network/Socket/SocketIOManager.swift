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
    private var isConnected: Bool = false

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

    deinit {
        print("소켓 디이닛 (나올수 없는 상황)")
    }
}

// MARK: - Connection
extension SocketIOManager {

    func connectDTO<T: DTO>(to socketCase: SocketCase, type: T.Type, shouldJoinRoom: Bool = true) -> AsyncStream<Result<T, NetworkError>> {
        let base = APIKey.socketURL
        guard let url = URL(string: base) else {
            print("❌ 유효하지 않은 소켓 URL")
            return AsyncStream { continuation in
                continuation.yield(.failure(.invalidURL))
                continuation.finish()
            }
        }
        print("🌐 소켓 요청 URL: " + url.absoluteString)
        print("📍 소켓 네임스페이스: \(socketCase.namespace)")

        // 토큰 가져오기 (동기 방식)
        let token = KeychainAuthStorage.shared.readAccessSync() ?? ""
        print("🔑 토큰 길이: \(token.count)")

        let config: SocketIOClientConfiguration = [
            .log(false), // 프로덕션에서는 false
            .compress,
            .reconnects(true),
            .reconnectWait(5),
            .reconnectAttempts(-1),
            .forceNew(false), // 같은 네임스페이스는 재사용
            .secure(false),
            .extraHeaders(["SeSacKey": APIKey.sesacKey, "Authorization": token])
        ]

        // 기존 소켓이 없거나 다른 네임스페이스면 새로 생성
        if manager == nil {
            print("🔧 새 SocketManager 생성")
            manager = SocketManager(socketURL: url, config: config)
        }

        print("🔧 소켓 생성 중 (네임스페이스: \(socketCase.namespace))")
        socket = manager?.socket(forNamespace: socketCase.namespace)
        print("✅ 소켓 인스턴스 생성 완료")

        return AsyncStream { [weak self] continuation in
            guard let self else {
                print("소켓에 Weak Self Error")
                continuation.yield(.failure(.weakSelf))
                continuation.finish()
                return
            }

            print("소켓 AsyncStream Start")
            self.setupSocketHandlers(
                continuation: continuation,
                type: type,
                eventName: socketCase.eventName,
                socketCase: socketCase,
                shouldJoinRoom: shouldJoinRoom
            )

            print("🔌 소켓 연결 시도 중...")
            socket?.connect()

            continuation.onTermination = { @Sendable _ in
                print("🔌 소켓 AsyncStream 종료")
                self.stopSocket()
            }
        }
    }

    private func setupSocketHandlers<T: DTO>(
        continuation: AsyncStream<Result<T, NetworkError>>.Continuation,
        type: T.Type,
        eventName: String,
        socketCase: SocketCase,
        shouldJoinRoom: Bool
    ) {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ 소켓 연결 성공 (네임스페이스 연결 = Room 입장 완료)")
            print("Data: \(data), Ack: \(ack)")
            self?.isConnected = true
            // 네임스페이스(/chats-{roomId})에 연결하는 것 자체가 room join이므로
            // 별도의 join emit 불필요
        }

        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("❌ 소켓 연결 종료")
            print("Data: \(data), Ack: \(ack)")
            self?.isConnected = false
        }

        socket?.on(clientEvent: .error) { [weak self] data, ack in
            print("⚠️ 소켓 에러 발생")
            print("📋 에러 데이터: \(data)")
            if let errorArray = data as? [Any] {
                print("📋 에러 배열 개수: \(errorArray.count)")
                if let firstError = errorArray.first {
                    print("📋 첫 번째 에러: \(firstError)")
                }
            }
            continuation.yield(.failure(.socketError))
            self?.stopAndRemoveSocket()
            continuation.finish()
        }

        socket?.on(clientEvent: .reconnect) { data, ack in
            print("🔄 소켓 재연결 중...")
        }

        socket?.on(clientEvent: .reconnectAttempt) { data, ack in
            print("🔄 소켓 재연결 시도 중...")
        }

        // 모든 이벤트 캐치 (디버깅용)
        socket?.onAny { event in
            print("🔔 [Socket] 이벤트 수신: \(event.event)")
            print("📋 [Socket] 이벤트 데이터: \(event.items ?? [])")
        }

        socket?.on(eventName) { dataArray, ack in
            print("📨 소켓 메시지 수신: \(eventName)")
            print("📋 원본 데이터: \(dataArray)")
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
                print("❌ 에러 상세: \(error.localizedDescription)")
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

