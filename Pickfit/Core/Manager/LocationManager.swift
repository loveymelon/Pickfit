//
//  LocationManager.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-30.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    // 기본 좌표 (서울 시청)
    private let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0)

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// 현재 위치를 가져옵니다. 권한이 없거나 실패 시 기본 좌표를 반환합니다.
    func getCurrentLocation() async -> CLLocationCoordinate2D {
        // 권한 상태 확인
        let authorizationStatus: CLAuthorizationStatus

        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        switch authorizationStatus {
        case .notDetermined:
            // 권한 요청
            print("📍 [Location] Requesting location permission")
            locationManager.requestWhenInUseAuthorization()

            // 권한 요청 후 위치 가져오기 시도
            return await fetchLocation()

        case .restricted, .denied:
            // 권한 거부됨 - 기본 좌표 반환
            print("⚠️ [Location] Permission denied, using default coordinate")
            return defaultCoordinate

        case .authorizedWhenInUse, .authorizedAlways:
            // 권한 있음 - 위치 가져오기
            return await fetchLocation()

        @unknown default:
            print("⚠️ [Location] Unknown authorization status")
            return defaultCoordinate
        }
    }

    private func fetchLocation() async -> CLLocationCoordinate2D {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = continuation
                self.locationManager.requestLocation()
            }
        } catch {
            print("❌ [Location] Failed to get location: \(error.localizedDescription)")
            print("ℹ️ [Location] Using default coordinate")
            return defaultCoordinate
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print("⚠️ [Location] No location data")
            locationContinuation?.resume(returning: defaultCoordinate)
            locationContinuation = nil
            return
        }

        let coordinate = location.coordinate
        print("✅ [Location] Got location: \(coordinate.latitude), \(coordinate.longitude)")

        // ⚠️ 주의: 실제 좌표를 사용하면 서버의 가짜 데이터가 안 나올 수 있음
        // 따라서 기본 좌표를 반환 (포트폴리오용)
        print("ℹ️ [Location] Using default coordinate for demo purposes")
        locationContinuation?.resume(returning: defaultCoordinate)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ [Location] Error: \(error.localizedDescription)")
        locationContinuation?.resume(returning: defaultCoordinate)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus

        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        print("📍 [Location] Authorization changed: \(status.rawValue)")
    }
}
