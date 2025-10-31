//
//  ImageResizer.swift
//  Pickfit
//
//  Created by 김진수 on 10/13/25.
//

import UIKit

/// 이미지 리사이징 및 압축 유틸리티
/// - 채팅 이미지 업로드 전 용량 최적화
struct ImageResizer {

    /// 이미지를 리사이징하고 압축
    /// - Parameters:
    ///   - image: 원본 UIImage
    ///   - maxDimension: 긴 변의 최대 크기 (기본 1280px)
    ///   - compressionQuality: JPEG 압축 품질 (0.0 ~ 1.0, 기본 0.7)
    /// - Returns: 압축된 Data (nil이면 실패)
    static func resize(
        image: UIImage,
        maxDimension: CGFloat = 1280,
        compressionQuality: CGFloat = 0.7
    ) -> Data? {

        // 1. 리사이징이 필요한지 체크
        let originalSize = image.size
        let needsResize = originalSize.width > maxDimension || originalSize.height > maxDimension

        let resizedImage: UIImage

        if needsResize {
            // 2. 비율 유지하면서 리사이징
            let ratio = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
            let newSize = CGSize(
                width: originalSize.width * ratio,
                height: originalSize.height * ratio
            )

            print("📐 [ImageResizer] Resizing from \(originalSize) to \(newSize)")

            // 3. UIGraphicsImageRenderer로 고품질 리사이징
            let renderer = UIGraphicsImageRenderer(size: newSize)
            resizedImage = renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            resizedImage = image
            print("📐 [ImageResizer] No resize needed: \(originalSize)")
        }

        // 4. JPEG 압축
        guard let compressedData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            print("❌ [ImageResizer] JPEG compression failed")
            return nil
        }

        let originalDataSize = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        let compressedSize = compressedData.count
        let compressionRatio = originalDataSize > 0 ? Double(compressedSize) / Double(originalDataSize) : 1.0

        print("✅ [ImageResizer] Compressed: \(formatBytes(originalDataSize)) → \(formatBytes(compressedSize)) (ratio: \(String(format: "%.1f%%", compressionRatio * 100)))")

        return compressedData
    }

    /// 여러 이미지를 한 번에 리사이징
    /// - Parameters:
    ///   - images: 원본 이미지 배열
    ///   - maxDimension: 긴 변의 최대 크기
    ///   - compressionQuality: JPEG 압축 품질
    /// - Returns: 압축된 Data 배열 (실패한 이미지는 제외)
    static func resizeMultiple(
        images: [UIImage],
        maxDimension: CGFloat = 1280,
        compressionQuality: CGFloat = 0.7
    ) -> [Data] {
        return images.compactMap { image in
            resize(image: image, maxDimension: maxDimension, compressionQuality: compressionQuality)
        }
    }

    /// 바이트를 읽기 쉬운 문자열로 변환
    private static func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
