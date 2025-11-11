//
//  RealmManager.swift
//  Pickfit
//
//  Created by 김진수 on 11/10/24.
//

import RealmSwift

/// Realm 데이터베이스 매니저
/// Actor 기반으로 thread-safe한 Realm 접근 보장
final actor RealmManager {

    static let shared = RealmManager()

    private var realm: Realm?

    private init() {
        Task {
            await self.setup()
        }
    }

    private func setup() async {
        do {
            realm = try await Realm()
#if DEBUG
            print("[RealmManager] Realm 초기화 성공: \(realm?.configuration.fileURL?.absoluteString ?? "")")
#endif
        } catch {
            print("[RealmManager] Realm 초기화 실패: \(error)")
            realm = nil
        }
    }

    /// Realm 인스턴스 반환
    func getRealm() async throws -> Realm {
        if let realm = realm {
            return realm
        }

        // realm이 nil이면 재초기화 시도
        await setup()

        guard let realm = realm else {
            throw RealmError.initializationFailed
        }

        return realm
    }
}

enum RealmError: Error {
    case initializationFailed
    case createFailed
    case fetchFailed
    case updateFailed
    case deleteFailed
}
