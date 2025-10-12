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
final class CoreDataManager {

    // MARK: - Singleton

    static let shared = CoreDataManager()

    private init() {
        // Singleton 초기화
    }

    // MARK: - Core Data Stack

    /// NSPersistentCloudKitContainer: CloudKit 자동 동기화 지원
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        // "Message"는 .xcdatamodeld 파일명
        let container = NSPersistentCloudKitContainer(name: "Message")

        // Persistent Store Description 설정
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("❌ CoreData: persistentStoreDescriptions가 없습니다")
        }

        // CloudKit Container 설정
        // iCloud.Pickfit은 Entitlements에 설정된 Container ID
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.Pickfit"
        )

        // 🔥 CloudKit 동기화 옵션
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Persistent Store 로드
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // 개발 중 에러 처리
                fatalError("❌ CoreData 로드 실패: \(error), \(error.userInfo)")
            }

            print("✅ CoreData 로드 성공: \(storeDescription.url?.lastPathComponent ?? "unknown")")
        }

        // ViewContext 설정
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // 🔥 CloudKit 변경 사항 자동 merge
        container.viewContext.automaticallyMergesChangesFromParent = true

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
            print("✅ CoreData 저장 성공 (자동으로 CloudKit에 동기화됨)")
        } catch {
            let nsError = error as NSError
            print("❌ CoreData 저장 실패: \(nsError), \(nsError.userInfo)")
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
                print("✅ CoreData 백그라운드 저장 성공")
            } catch {
                let nsError = error as NSError
                print("❌ CoreData 백그라운드 저장 실패: \(nsError)")
            }
        }
    }
}
