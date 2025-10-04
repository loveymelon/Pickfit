//
//  StoreListView.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import SnapKit
import Then

final class StoreListView: BaseView {
    let tableView = UITableView().then {
        $0.register(StoreCell.self, forCellReuseIdentifier: StoreCell.identifier)
        $0.backgroundColor = .white
        $0.separatorStyle = .none
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 250
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(tableView)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
