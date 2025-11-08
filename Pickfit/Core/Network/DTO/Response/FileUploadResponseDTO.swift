//
//  FileUploadResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/13/25.
//

import Foundation

/// 파일 업로드 응답 DTO
/// POST /v1/chats/{room_id}/files
struct FileUploadResponseDTO: DTO {
    let files: [String]  // 업로드된 파일 경로 배열

    // 예시 응답:
    // {
    //   "files": [
    //     "/data/chats/IMG_4400_1729345641848.jpg",
    //     "/data/chats/IMG_4401_1729345641849.jpg"
    //   ]
    // }
}
