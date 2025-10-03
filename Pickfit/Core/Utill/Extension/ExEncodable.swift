//
//  ExEncodable.swift
//  Pickfit
//
//  Created by 김진수 on 10/3/25.
//

import Foundation

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONCoder.encode(self)
        let json = try JSONSerialization.jsonObject(with: data)
        return json as? [String: Any] ?? [:]
    }
}
