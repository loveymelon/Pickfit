//
//  ShoppingCartView.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import UIKit
import SnapKit
import Then

final class ShoppingCartView: BaseView {
    let tableView = UITableView().then {
        $0.backgroundColor = .white
        $0.separatorStyle = .singleLine
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 100
    }

    let emptyLabel = UILabel().then {
        $0.text = "장바구니가 비어있습니다"
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .systemGray
        $0.textAlignment = .center
        $0.isHidden = true
    }

    let purchaseButton = UIButton(type: .system).then {
        $0.setTitle("구매하기", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        $0.backgroundColor = .black
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 8
    }

    private let bottomContainerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowOffset = CGSize(width: 0, height: -3)
        $0.layer.shadowRadius = 10
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(tableView)
        addSubview(emptyLabel)
        addSubview(bottomContainerView)
        bottomContainerView.addSubview(purchaseButton)
    }

    override func configureLayout() {
        bottomContainerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
            $0.height.equalTo(80)
        }

        purchaseButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }

        tableView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalTo(bottomContainerView.snp.top)
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // 상단에만 그림자가 보이도록 shadowPath 설정
        let shadowRect = CGRect(x: 0, y: -10, width: bottomContainerView.bounds.width, height: 10)
        bottomContainerView.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
    }

    override func configureUI() {
        super.configureUI()
        backgroundColor = .white
    }

    func updatePurchaseButton(totalQuantity: Int, totalPrice: Int) {
        let formattedPrice = formatPrice(totalPrice)
        purchaseButton.setTitle("구매하기 (\(totalQuantity)개) · \(formattedPrice)원", for: .normal)
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}
