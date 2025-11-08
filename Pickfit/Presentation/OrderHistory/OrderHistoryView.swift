//
//  OrderHistoryView.swift
//  Pickfit
//
//  Created by 김진수 on 10/10/25.
//

import UIKit
import SnapKit
import Then

final class OrderHistoryView: BaseView {

    let tableView = UITableView().then {
        $0.backgroundColor = .systemGroupedBackground
        $0.separatorStyle = .none
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 180
        $0.register(OrderHistoryCell.self, forCellReuseIdentifier: OrderHistoryCell.identifier)
        $0.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    let emptyLabel = UILabel().then {
        $0.text = "주문 내역이 없습니다"
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .systemGray
        $0.textAlignment = .center
        $0.isHidden = true
    }

    let refreshControl = UIRefreshControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(tableView)
        addSubview(emptyLabel)
        tableView.refreshControl = refreshControl
    }

    override func configureLayout() {
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    override func configureUI() {
        super.configureUI()
        backgroundColor = .systemGroupedBackground
    }

    func showEmpty(_ isEmpty: Bool) {
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
}
