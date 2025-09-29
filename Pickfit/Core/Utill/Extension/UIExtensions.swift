//
//  UIExtensions.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit

protocol ReusableProtocol {
    static var identifier: String { get }
}

extension UIView: ReusableProtocol {
    static var identifier: String {
        return String(describing: self)
    }
}

protocol UIConfigureProtocol {
    func configureUI()
    func configureHierarchy()
    func configureLayout()
}