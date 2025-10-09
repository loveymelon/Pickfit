//
//  CartBarButtonView.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import UIKit
import SnapKit
import Then

final class CartBarButtonView: UIView {
    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "shoppingCart")
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .black
    }

    private let badgeLabel = UILabel().then {
        $0.backgroundColor = .red
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 10, weight: .bold)
        $0.textAlignment = .center
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
        $0.isHidden = true
    }

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(imageView)
        addSubview(badgeLabel)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.height.equalTo(28)
        }

        badgeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(-4)
            $0.trailing.equalToSuperview().offset(4)
            $0.width.height.greaterThanOrEqualTo(16)
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }

    func updateBadge(count: Int) {
        if count > 0 {
            badgeLabel.isHidden = false
            if count > 99 {
                badgeLabel.text = "99+"
                badgeLabel.snp.updateConstraints {
                    $0.width.greaterThanOrEqualTo(20)
                }
            } else {
                badgeLabel.text = "\(count)"
                badgeLabel.snp.updateConstraints {
                    $0.width.height.greaterThanOrEqualTo(16)
                }
            }
        } else {
            badgeLabel.isHidden = true
        }
    }
}
