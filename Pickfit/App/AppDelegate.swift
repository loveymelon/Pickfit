//
//  AppDelegate.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit
import KakaoSDKCommon
import iamport_ios
import CloudKit
import FirebaseCore
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        KakaoSDK.initSDK(appKey: APIKey.kakaoKey)

        // iCloud 계정 상태 체크 (비동기)
        checkiCloudAccountStatus()

        // CoreData + CloudKit 초기화
        _ = CoreDataManager.shared.persistentContainer

        // Firebase 초기화
        FirebaseApp.configure()

        // 푸시 알림 설정 (Firebase 초기화 후에 설정해야 함)
        setPushSetting()

        // APNS 등록 (비동기) - 완료되면 didRegisterForRemoteNotificationsWithDeviceToken 호출됨
        application.registerForRemoteNotifications()

        // FCM 토큰 수신을 위한 delegate 설정
        Messaging.messaging().delegate = self

        // ⭐ Notification delegate 강제 재설정 (Firebase가 덮어쓰는 것 방지)
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Iamport.shared.receivedURL(url)
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// 앱이 Foreground(실행 중)일 때 푸시 알림을 받으면 호출됨
    /// - Returns: 알림을 어떻게 표시할지 옵션
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 [AppDelegate] Received notification while app is in foreground")

        let userInfo = notification.request.content.userInfo
        let content = notification.request.content
        print("📋 [AppDelegate] Notification userInfo: \(userInfo)")

        // Firebase 푸시에서 데이터 추출 (room_id 또는 roomId)
        let roomId = userInfo["room_id"] as? String ?? userInfo["roomId"] as? String

        if let roomId = roomId {
            // ⭐ 같은 방을 보고 있으면 알림 무시
            if ChatStateManager.shared.isRoomActive(roomId) {
                print("🔕 [AppDelegate] Same room active, skip notification for room: \(roomId)")
                completionHandler([])  // 알림 표시 안 함
                return
            }

            // ⭐ 배지 개수 증가 (같은 방을 보고 있지 않을 때만)
            BadgeManager.shared.incrementUnreadCount(for: roomId)
            print("📊 [AppDelegate] Badge incremented for room: \(roomId)")

            // ⭐ 채팅 목록 갱신 알림 발송 (채팅 목록 뷰가 자동으로 갱신됨)
            NotificationCenter.default.post(
                name: .chatPushReceived,
                object: nil,
                userInfo: ["roomId": roomId]
            )
            print("📬 [AppDelegate] Posted chatPushReceived notification for room: \(roomId)")

            print("🔔 [AppDelegate] Chat message push - showing notification for room: \(roomId)")

            // ⭐ 여기가 푸시 데이터가 나오는 부분
            print("📋 [AppDelegate] Title: \(content.title)")
            print("📋 [AppDelegate] Subtitle: \(content.subtitle ?? "nil")")
            print("📋 [AppDelegate] Body: \(content.body)")

            // 서버가 보낸 알림 그대로 표시
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            print("🔔 [AppDelegate] Test/General push - showing system notification")

            // roomId가 없는 푸시 (테스트, 일반 알림 등) → 시스템 알림 표시
            completionHandler([.banner, .sound, .badge, .list])
        }
    }

    /// 사용자가 푸시 알림을 탭했을 때 호출됨 (Background → Foreground)
    /// - 푸시에 포함된 roomId를 읽어서 해당 채팅방을 열어줌
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🔔 [AppDelegate] User tapped on notification")

        let userInfo = response.notification.request.content.userInfo
        print("📋 [AppDelegate] Notification userInfo: \(userInfo)")

        // roomId 추출 (room_id 또는 roomId)
        let roomId = userInfo["room_id"] as? String ?? userInfo["roomId"] as? String

        if let roomId = roomId {
            print("📱 [AppDelegate] Opening chat room: \(roomId)")

            // ⚠️ 주의: 배지 증가는 willPresent에서만 하고 여기서는 안 함!
            // 이유: Foreground에서 받은 푸시는 이미 willPresent에서 증가했음
            // Background에서 받은 푸시는 OS가 자동으로 배지 증가함

            // SceneDelegate에게 "이 채팅방 열어줘" 신호 보내기
            NotificationCenter.default.post(
                name: .openChatRoom,
                object: nil,
                userInfo: ["roomId": roomId]
            )
        } else {
            print("⚠️ [AppDelegate] No roomId found in notification")
        }

        completionHandler()
    }

    /// APNS deviceToken을 받으면 Firebase Messaging에 전달
    /// - 이 메서드 호출 후 Firebase가 자동으로 FCM 토큰을 발급하여 messaging(_:didReceiveRegistrationToken:) 호출
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 [AppDelegate] APNS deviceToken received: \(deviceToken)...")

        // ✅ APNS 토큰을 Firebase Messaging에 전달
        // 이후 Firebase가 FCM 토큰을 자동으로 발급
        Messaging.messaging().apnsToken = deviceToken
        print("✅ [AppDelegate] APNS token set to Firebase Messaging")
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
            }
        }
        
    }

    /// APNS 등록 실패 시 호출
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - MessagingDelegate (Firebase)

extension AppDelegate: MessagingDelegate {

    /// FCM 토큰을 받으면 호출됨
    /// - 타이밍 1: APNS 토큰 수신 후 Firebase가 FCM 토큰 자동 발급 (앱 시작 시)
    /// - 타이밍 2: 토큰 갱신 시 (앱 재설치, 토큰 만료 등)
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 [AppDelegate] FCM token received (delegate called)")

        guard let token = fcmToken else {
            print("⚠️ [AppDelegate] FCM token is nil")
            return
        }

        print("📤 [AppDelegate] FCM Token: \(token)...")

        // 이전 토큰 조회 (중복 호출 방지용)
        let previousToken = UserDefaults.standard.string(forKey: "deviceToken")

        // ✅ FCM 토큰을 UserDefaults에 저장
        UserDefaults.standard.set(token, forKey: "deviceToken")
        print("✅ [AppDelegate] FCM Token saved to UserDefaults")

        // ⭐ 토큰이 실제로 변경되었을 때만 서버 업데이트
        if let previous = previousToken, previous != token {
            print("🔄 [AppDelegate] FCM Token changed, updating server...")
            print("   - Previous: \(previous.prefix(30))...")
            print("   - New: \(token.prefix(30))...")
            Task {
                await updateTokenToServerIfLoggedIn(token)
            }
        } else if previousToken == nil {
            print("ℹ️ [AppDelegate] First token received, will be sent on login")
        } else {
            print("ℹ️ [AppDelegate] Token unchanged, skip server update")
        }

        // Optional: FCM 토큰 알림 (필요 시 다른 곳에서 구독 가능)
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: ["token": token]
        )
    }

    /// 로그인 상태일 때만 서버에 FCM 토큰 업데이트
    /// - Parameter token: 업데이트할 FCM 토큰
    /// - Note: 토큰 갱신 시 자동으로 서버 동기화
    private func updateTokenToServerIfLoggedIn(_ token: String) async {
        // 로그인 상태 확인
        guard await KeychainAuthStorage.shared.readAccess() != nil else {
            print("⚠️ [AppDelegate] Not logged in, skip token update to server")
            return
        }

        print("📤 [AppDelegate] Updating FCM token to server...")

        do {
            try await NotificationRepository().updateDeviceToken(token)
            print("✅ [AppDelegate] FCM Token updated to server successfully")
        } catch {
            print("❌ [AppDelegate] Failed to update token to server: \(error.localizedDescription)")
            // 실패해도 앱은 정상 작동 (다음 로그인 시 재시도)
        }
    }
}

extension AppDelegate {
    // MARK: - iCloud Account Status Check

    /// iCloud 계정 상태 확인
    /// 앱 시작 시 iCloud 사용 가능 여부를 체크하여 동기화 불가 상황 사전 감지
    private func checkiCloudAccountStatus() {
        let container = CKContainer(identifier: "iCloud.Pickfit")

        container.accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    print("[iCloud] 계정 사용 가능 - CloudKit 동기화 활성화")

                case .noAccount:
                    print("[iCloud] 경고: iCloud 계정이 없습니다")
                    // TODO: 사용자에게 iCloud 로그인 안내
                    // 예: "iCloud에 로그인하면 모든 기기에서 채팅 내역을 볼 수 있습니다"

                case .restricted:
                    print("[iCloud] 경고: iCloud 사용이 제한되었습니다 (자녀 보호 기능 등)")
                    // TODO: 로컬 전용 모드로 전환

                case .couldNotDetermine:
                    print("[iCloud] 경고: iCloud 상태를 확인할 수 없습니다")
                    if let error = error {
                        print("[iCloud] 에러: \(error.localizedDescription)")
                    }

                case .temporarilyUnavailable:
                    print("[iCloud] 경고: iCloud를 일시적으로 사용할 수 없습니다")
                    // TODO: 재시도 로직 또는 사용자 안내

                @unknown default:
                    print("[iCloud] 알 수 없는 상태: \(status.rawValue)")
                }
            }
        }
    }
    
    private func setPushSetting() {
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                print("✅ [AppDelegate] Push notification permission granted")
            } else {
                print("❌ [AppDelegate] Push notification permission denied")
            }
            if let error = error {
                print("⚠️ [AppDelegate] Push permission error: \(error.localizedDescription)")
            }
        }
    }
}
