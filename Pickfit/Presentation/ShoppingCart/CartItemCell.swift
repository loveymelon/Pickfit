//
//  CartItemCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import UIKit
import SnapKit
import Then

final class CartItemCell: UITableViewCell {
    private let productImageView = ImageLoadView(cornerRadius: 8).then {
        $0.backgroundColor = .systemGray6
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .black
        $0.numberOfLines = 2
    }

    private let optionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .systemGray
        $0.numberOfLines = 1
    }

    private let minusButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "minus"), for: .normal)
        $0.tintColor = .black
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 15
    }

    private let quantityLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .black
        $0.textAlignment = .center
    }

    private let plusButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "plus"), for: .normal)
        $0.tintColor = .black
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 15
    }

    private let priceLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
        $0.textAlignment = .right
    }

    private let deleteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .systemGray
    }

    var onQuantityChanged: ((Int) -> Void)?
    var onDelete: (() -> Void)?

    private var currentQuantity: Int = 1

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.addSubview(productImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(optionLabel)
        contentView.addSubview(minusButton)
        contentView.addSubview(quantityLabel)
        contentView.addSubview(plusButton)
        contentView.addSubview(priceLabel)
        contentView.addSubview(deleteButton)

        productImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(16)
            $0.width.height.equalTo(80)
        }

        deleteButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(16)
            $0.width.height.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(productImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(deleteButton.snp.leading).offset(-8)
            $0.top.equalTo(productImageView)
        }

        optionLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
        }

        minusButton.snp.makeConstraints {
            $0.leading.equalTo(productImageView.snp.trailing).offset(12)
            $0.bottom.equalToSuperview().offset(-16)
            $0.width.height.equalTo(30)
        }

        quantityLabel.snp.makeConstraints {
            $0.leading.equalTo(minusButton.snp.trailing).offset(12)
            $0.centerY.equalTo(minusButton)
            $0.width.equalTo(30)
        }

        plusButton.snp.makeConstraints {
            $0.leading.equalTo(quantityLabel.snp.trailing).offset(12)
            $0.centerY.equalTo(minusButton)
            $0.width.height.equalTo(30)
        }

        priceLabel.snp.makeConstraints {
            $0.trailing.equalTo(deleteButton)
            $0.centerY.equalTo(minusButton)
        }
    }

    private func setupActions() {
        minusButton.addTarget(self, action: #selector(minusButtonTapped), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    @objc private func minusButtonTapped() {
        if currentQuantity > 1 {
            currentQuantity -= 1
            updateQuantity()
            onQuantityChanged?(currentQuantity)
        }
    }

    @objc private func plusButtonTapped() {
        currentQuantity += 1
        updateQuantity()
        onQuantityChanged?(currentQuantity)
    }

    @objc private func deleteButtonTapped() {
        onDelete?()
    }

    private func updateQuantity() {
        quantityLabel.text = "\(currentQuantity)"
    }

    func configure(with item: CartItem) {
        // 로컬 이미지가 있으면 사용, 없으면 URL 로드 또는 회색 배경
        let imageUrl = item.menu.menuImageUrl

        if !imageUrl.isEmpty, UIImage(named: imageUrl) != nil {
            // 로컬 에셋 이미지
            productImageView.image = UIImage(named: imageUrl)
        } else if imageUrl.hasPrefix("http") {
            // 원격 URL 이미지
            productImageView.loadImage(from: imageUrl)
        } else {
            // 이미지 없음 - 회색 배경
            productImageView.image = nil
            productImageView.backgroundColor = .systemGray5
        }

        titleLabel.text = item.menu.name
        optionLabel.text = "\(item.color) / \(item.size)"
        currentQuantity = item.quantity
        updateQuantity()

        let price = item.menu.price * item.quantity
        priceLabel.text = formatPrice(price) + "원"
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        productImageView.cancelLoading()
        currentQuantity = 1
    }
}
