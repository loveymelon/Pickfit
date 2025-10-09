//
//  OrderRequestDTO.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import Foundation

struct OrderRequestDTO: Encodable {
    let storeId: String
    let orderMenuList: [OrderMenuDTO]
    let totalPrice: Int

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case orderMenuList = "order_menu_list"
        case totalPrice = "total_price"
    }
}

struct OrderMenuDTO: Encodable {
    let menuId: String
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case menuId = "menu_id"
        case quantity
    }
}
