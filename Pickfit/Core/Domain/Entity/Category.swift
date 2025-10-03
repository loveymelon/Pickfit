//
//  Category.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import Foundation

enum Category: String, CaseIterable {
    case sport
    case street
    case dandy
    case formal
    case american
    case modern
    case casual
    case homeWare

    var imageName: String {
        return self.rawValue
    }

    var displayName: String {
        switch self {
        case .sport: return "스포츠"
        case .street: return "스트릿"
        case .dandy: return "댄디"
        case .formal: return "포멀"
        case .american: return "아메카지"
        case .modern: return "모던"
        case .casual: return "캐주얼"
        case .homeWare: return "홈웨어"
        }
    }

    var apiValue: String {
        return "Jin\(self.rawValue.capitalized)"
    }
}
