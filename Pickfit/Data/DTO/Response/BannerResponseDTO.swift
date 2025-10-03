//
//  BannerResponseDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import Foundation

struct BannerResponseDTO: DTO {
    let data: [Banner]

    struct Banner: DTO, Equatable {
        let name: String
        let imageUrl: String
        let payload: Payload

        struct Payload: DTO, Equatable {
            let type: String
            let value: String
        }
    }
}
