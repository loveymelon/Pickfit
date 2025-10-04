//
//  StoreDetailViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import RxSwift

final class StoreDetailViewController: BaseViewController<StoreDetailView> {
    
    private let reactor: StoreDetailReactor
    
    init(storeId: String) {
        self.reactor = StoreDetailReactor(storeId: storeId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
}
