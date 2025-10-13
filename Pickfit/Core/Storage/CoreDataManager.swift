//
//  CoreDataManager.swift
//  Pickfit
//
//  Created by Claude on 10/12/25.
//

import Foundation
import CoreData
import CloudKit

/// CoreData + CloudKit 통합 관리자
/// NSPersistentCloudKitContainer를 사용하여 자동 iCloud 동기화 제공
///
/// ## iCloud 용량 초과 처리
/// - 용량 초과 시: 로컬 저장은 정상 작동, CloudKit 동기화만 중단
/// - 감지 방법: CKError.quotaExceeded (code 25/2035) 또는 partialFailure 내부 체크
/// - 알림: NotificationCenter를 통해 .cloudKitQuotaExceeded 전송
/// - UI 연동: ViewController에서 Notification 수신하여 사용자 안내
///
/// ## README 작성 참고
/// ### iCloud 저장 공간 부족 시 동작
/// 1. 로컬 앱: 정상 작동 (CoreData 저장 계속)
/// 2. 동기화: 중단 (새 데이터가 다른 기기로 전송 안 됨)
/// 3. 사용자 알림: "iCloud 저장 공간이 부족합니다" 메시지 표시
/// 4. 해결 방법: 설정 > [사용자 이름] > iCloud > 저장 공간 관리
final class CoreDataManager {

    // MARK: - Singleton

    static let shared = CoreDataManager()

    private init() {
        setupCloudKitNotifications()
    }

    // MARK: - Core Data Stack

    /// NSPersistentCloudKitContainer: CloudKit 자동 동기화 지원
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        // "Message"는 .xcdatamodeld 파일명
        let container = NSPersistentCloudKitContainer(name: "Message")

        // Persistent Store Description 설정
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("[CoreData] persistentStoreDescriptions가 없습니다")
        }

        // CloudKit Container 설정
        // iCloud.Pickfit은 Entitlements에 설정된 Container ID
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.Pickfit"
        )

        // CloudKit 동기화 필수 옵션
        // - NSPersistentHistoryTrackingKey: 변경 이력 추적 (다중 기기 동기화에 필수)
        // - NSPersistentStoreRemoteChangeNotificationPostOptionKey: 원격 변경 알림 수신
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Persistent Store 로드
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // 개발 중 에러 처리
                fatalError("[CoreData] 로드 실패: \(error), \(error.userInfo)")
            }

            print("[CoreData] 로드 성공: \(storeDescription.url?.lastPathComponent ?? "unknown")")
        }

        // ViewContext 설정
        // - automaticallyMergesChangesFromParent: CloudKit 변경사항 자동 병합
        // - mergePolicy: 충돌 시 서버(CloudKit) 데이터 우선 (채팅 앱 특성상 서버가 Single Source of Truth)
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        return container
    }()

    /// Main thread에서 사용하는 ViewContext
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// Background thread에서 사용하는 Context 생성
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    // MARK: - Save Context

    /// ViewContext 저장 (Main thread)
    func saveContext() {
        let context = viewContext

        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
            print("[CoreData] 저장 성공 (자동으로 CloudKit에 동기화됨)")
        } catch {
            let nsError = error as NSError
            print("[CoreData] 저장 실패: \(nsError), \(nsError.userInfo)")
        }
    }

    /// Background Context 저장
    func saveBackgroundContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else {
            return
        }

        context.perform {
            do {
                try context.save()
                print("[CoreData] 백그라운드 저장 성공")
            } catch {
                let nsError = error as NSError
                print("[CoreData] 백그라운드 저장 실패: \(nsError)")
            }
        }
    }

    // MARK: - CloudKit Sync Monitoring

    /// CloudKit 동기화 알림 설정
    /// Import/Export 이벤트를 모니터링하여 동기화 상태 추적
    private func setupCloudKitNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
    }

    /// CloudKit 동기화 이벤트 처리
    /// - Parameter notification: NSPersistentCloudKitContainer.eventChangedNotification
    /// - Note: quotaExceeded 에러를 감지하여 사용자에게 알림
    @objc private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }

        // 에러가 있으면 quotaExceeded 체크
        if let error = event.error {
            checkForQuotaExceededError(error)
        }

        // 이벤트 타입별 처리
        switch event.type {
        case .setup:
            print("[CloudKit] 초기 설정 완료")

        case .import:
            print("[CloudKit] Import 완료")
            if let error = event.error {
                print("[CloudKit] Import 에러: \(error.localizedDescription)")
                // TODO: 사용자에게 동기화 실패 알림 (예: 토스트 메시지)
            }

        case .export:
            print("[CloudKit] Export 완료")
            if let error = event.error {
                print("[CloudKit] Export 에러: \(error.localizedDescription)")
                // TODO: 사용자에게 업로드 실패 알림
            }

        @unknown default:
            print("[CloudKit] 알 수 없는 이벤트: \(event)")
        }
    }

    /// iCloud 용량 초과 에러 체크
    /// - Parameter error: CloudKit 에러
    /// - Note: quotaExceeded는 직접 발생하거나 partialFailure 내부에 포함될 수 있음
    private func checkForQuotaExceededError(_ error: Error) {
        guard let ckError = error as? CKError else {
            return
        }

        switch ckError.code {
        case .quotaExceeded:
            // 직접적인 quotaExceeded 에러
            print("[CloudKit] 경고: iCloud 저장 공간 부족")
            notifyQuotaExceeded()

        case .partialFailure:
            // partialFailure 내부에 quotaExceeded가 있는지 체크
            if let partialErrors = ckError.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error] {
                for (_, itemError) in partialErrors {
                    if let itemCKError = itemError as? CKError,
                       itemCKError.code == .quotaExceeded {
                        print("[CloudKit] 경고: iCloud 저장 공간 부족 (partialFailure 내부)")
                        notifyQuotaExceeded()
                        break
                    }
                }
            }

        default:
            break
        }
    }

    /// iCloud 용량 초과 알림 전송
    /// - Note: NotificationCenter를 통해 앱 전체에 알림
    ///         ViewController에서 수신하여 사용자 UI 표시
    private func notifyQuotaExceeded() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .cloudKitQuotaExceeded,
                object: nil,
                userInfo: [
                    "message": "iCloud 저장 공간이 부족하여 데이터가 동기화되지 않습니다.",
                    "action": "iCloud 저장 공간을 확보해주세요."
                ]
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// iCloud 용량 초과 알림
    ///
    /// ## 사용 방법 (ViewController에서)
    /// ```swift
    /// NotificationCenter.default.addObserver(
    ///     forName: .cloudKitQuotaExceeded,
    ///     object: nil,
    ///     queue: .main
    /// ) { notification in
    ///     // Alert 또는 Toast 메시지 표시
    ///     let message = notification.userInfo?["message"] as? String ?? ""
    ///     let action = notification.userInfo?["action"] as? String ?? ""
    ///
    ///     // 예: UIAlertController
    ///     let alert = UIAlertController(
    ///         title: "저장 공간 부족",
    ///         message: "\(message)\n\(action)",
    ///         preferredStyle: .alert
    ///     )
    ///     alert.addAction(UIAlertAction(title: "설정 열기", style: .default) { _ in
    ///         if let url = URL(string: "App-prefs:root=CASTLE") {
    ///             UIApplication.shared.open(url)
    ///         }
    ///     })
    ///     alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
    ///     self.present(alert, animated: true)
    /// }
    /// ```
    static let cloudKitQuotaExceeded = Notification.Name("cloudKitQuotaExceeded")
}
