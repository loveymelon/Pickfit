//
//  EncodingType.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Alamofire

enum EncodingType {
    case url
    case json
    case multiPart(MultipartFormData)
}