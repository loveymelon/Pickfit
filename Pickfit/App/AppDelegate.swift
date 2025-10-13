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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        KakaoSDK.initSDK(appKey: APIKey.kakaoKey)

        // iCloud 계정 상태 체크 (비동기)
        checkiCloudAccountStatus()

        // CoreData + CloudKit 초기화
        _ = CoreDataManager.shared.persistentContainer

        return true
    }

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

