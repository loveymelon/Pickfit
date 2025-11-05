//
//  VideoThumbnailGenerator.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-22.
//

import UIKit
import AVFoundation

final class VideoThumbnailGenerator {

    static let shared = VideoThumbnailGenerator()

    private init() {}

    /// 동영상 URL에서 썸네일 이미지 생성
    /// - Parameters:
    ///   - url: 동영상 URL
    ///   - time: 추출할 시간 (기본값: 1초)
    ///   - accessToken: 인증 토큰 (옵션)
    /// - Returns: 썸네일 UIImage
    func generateThumbnail(from url: URL, at time: CMTime = CMTime(seconds: 1, preferredTimescale: 60), accessToken: String? = nil) async throws -> UIImage {
        // HTTP 헤더 설정 (인증)
        var headers: [String: String] = ["SeSACKey": APIKey.sesacKey]
        if let token = accessToken {
            headers["Authorization"] = token
        }

        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])

        // Asset의 tracks가 로드 가능한지 먼저 확인
        do {
            let tracks = try await asset.load(.tracks)
            guard !tracks.isEmpty else {
                print("❌ [VideoThumbnail] No video tracks found")
                throw VideoThumbnailError.noVideoTrack
            }
            print("✅ [VideoThumbnail] Video tracks loaded: \(tracks.count)")
        } catch {
            print("❌ [VideoThumbnail] Failed to load tracks: \(error.localizedDescription)")
            throw VideoThumbnailError.assetLoadFailed
        }

        let imageGenerator = AVAssetImageGenerator(asset: asset)

        // 정확한 프레임 추출 설정
        imageGenerator.appliesPreferredTrackTransform = true

        // 약간의 tolerance를 허용 (정확한 시간에 프레임이 없을 수 있음)
        imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 60)
        imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 60)

        // 썸네일 최대 크기 설정 (메모리 절약)
        imageGenerator.maximumSize = CGSize(width: 600, height: 600)

        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
                if let error = error {
                    print("❌ [VideoThumbnail] Failed to generate: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let cgImage = cgImage else {
                    print("❌ [VideoThumbnail] No CGImage generated")
                    continuation.resume(throwing: VideoThumbnailError.noImageGenerated)
                    return
                }

                let thumbnail = UIImage(cgImage: cgImage)
                print("✅ [VideoThumbnail] Thumbnail generated successfully")
                continuation.resume(returning: thumbnail)
            }
        }
    }

    /// 빠른 썸네일 생성 (0.1초 프레임)
    func generateQuickThumbnail(from url: URL, accessToken: String? = nil) async throws -> UIImage {
        // 0초가 아닌 0.1초로 시도 (일부 동영상은 0초에 프레임 없음)
        return try await generateThumbnail(from: url, at: CMTime(seconds: 0.1, preferredTimescale: 60), accessToken: accessToken)
    }
}

enum VideoThumbnailError: Error {
    case noImageGenerated
    case invalidURL
    case noVideoTrack
    case assetLoadFailed

    var localizedDescription: String {
        switch self {
        case .noImageGenerated:
            return "동영상 썸네일을 생성할 수 없습니다"
        case .invalidURL:
            return "잘못된 동영상 URL입니다"
        case .noVideoTrack:
            return "동영상 트랙을 찾을 수 없습니다"
        case .assetLoadFailed:
            return "동영상을 로드할 수 없습니다"
        }
    }
}
