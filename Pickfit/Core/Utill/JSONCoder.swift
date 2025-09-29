//
//  JSONCoder.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import Foundation

enum JSONCoder {
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()

        return try encoder.encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()

        return try decoder.decode(T.self, from: data)
    }

    static func toJSONSerialization(data: Data?) -> Any? {
        do {
            guard let data else {
                return nil
            }
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            return nil
        }
    }
}