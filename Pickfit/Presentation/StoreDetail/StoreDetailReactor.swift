//
//  StoreDetailReactor.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import RxSwift
import ReactorKit

final class StoreDetailReactor: Reactor {
    private let storeId: String
    
    enum Action {
        case load(Int)
    }
    
    enum Mutation {
        
    }
    
    struct State {
        
    }
    
    let initialState = State()
    
    init(storeId: String) {
        self.storeId = storeId
    }
}
