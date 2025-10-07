//
//  ProductInfoCell.swift
//  Pickfit
//
//  Created by 김진수 on 10/7/25.
//

import UIKit
import SnapKit
import Then
import RxSwift

final class ProductInfoCell: UICollectionViewCell {
    var disposeBag = DisposeBag()

    // MARK: - UI Components
    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    private let materialLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let countryLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let manufacturerLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let sizeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .label
        $0.text = "사이즈"
    }

    private let sizeStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.distribution = .fillEqually
    }

    private let colorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .label
        $0.text = "색상"
    }

    private let colorStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
    }

    private var sizeButtons: [UIButton] = []
    private var colorButtons: [UIButton] = []

    var onSizeSelected: ((String) -> Void)?
    var onColorSelected: ((String) -> Void)?

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        nameLabel.text = nil
        descriptionLabel.text = nil
        materialLabel.text = nil
        countryLabel.text = nil
        manufacturerLabel.text = nil
        sizeStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        colorStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sizeButtons.removeAll()
        colorButtons.removeAll()
    }

    // MARK: - Configure
    func configure(with productInfo: ProductInfo, selectedSize: String?, selectedColor: String?) {
        nameLabel.text = productInfo.name
        descriptionLabel.text = productInfo.description

        if let material = productInfo.material {
            materialLabel.text = "소재: \(material)"
        }

        if let country = productInfo.manufacturingCountry {
            countryLabel.text = "제조국: \(country)"
        }

        if let manufacturer = productInfo.manufacturer {
            manufacturerLabel.text = "제조사: \(manufacturer)"
        }

        // 사이즈 버튼 생성
        for size in productInfo.sizes {
            let isSoldOut = productInfo.soldOutSizes.contains(size)
            let button = createSizeButton(title: size, isSelected: size == selectedSize, isSoldOut: isSoldOut)
            sizeStackView.addArrangedSubview(button)
            sizeButtons.append(button)
        }

        // 색상 버튼 생성
        for color in productInfo.colors {
            let button = createColorButton(colorHex: color, isSelected: color == selectedColor)
            colorStackView.addArrangedSubview(button)
            colorButtons.append(button)
        }
    }

    private func createSizeButton(title: String, isSelected: Bool, isSoldOut: Bool) -> UIButton {
        // 품절이면 custom 타입, 아니면 system 타입
        let buttonType: UIButton.ButtonType = isSoldOut ? .custom : .system
        let button = UIButton(type: buttonType).then {
            $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            $0.layer.cornerRadius = 20
            $0.layer.borderWidth = 1.5
            $0.isEnabled = !isSoldOut
            $0.snp.makeConstraints { make in
                make.width.height.equalTo(40)
            }
        }

        if isSoldOut {
            // 품절 스타일: 회색 배경, 흐린 텍스트, 취소선
            button.backgroundColor = .systemGray5
            button.layer.borderColor = UIColor.systemGray4.cgColor

            // 취소선 추가
            let attributedTitle = NSAttributedString(
                string: title,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.systemGray3,
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                    .foregroundColor: UIColor.systemGray3
                ]
            )
            button.setAttributedTitle(attributedTitle, for: .normal)
            button.setAttributedTitle(attributedTitle, for: .disabled)
        } else {
            button.setTitle(title, for: .normal)
            updateSizeButton(button, isSelected: isSelected)

            button.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.onSizeSelected?(title)
                })
                .disposed(by: disposeBag)
        }

        return button
    }

    private func createColorButton(colorHex: String, isSelected: Bool) -> UIButton {
        let button = UIButton(type: .custom).then {
            $0.layer.cornerRadius = 20
            $0.layer.borderWidth = isSelected ? 2.5 : 1.5
            $0.layer.borderColor = isSelected ? UIColor.black.cgColor : UIColor.lightGray.cgColor
            $0.backgroundColor = UIColor(hex: colorHex) ?? .gray
            $0.snp.makeConstraints { make in
                make.width.height.equalTo(40)
            }
        }

        button.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.onColorSelected?(colorHex)
            })
            .disposed(by: disposeBag)

        return button
    }

    private func updateSizeButton(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.backgroundColor = .black
            button.setTitleColor(.white, for: .normal)
            button.layer.borderColor = UIColor.black.cgColor
        } else {
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
}

extension ProductInfoCell: UIConfigureProtocol {
    func configureUI() {
        configureHierarchy()
        configureLayout()
    }

    func configureHierarchy() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(materialLabel)
        contentView.addSubview(countryLabel)
        contentView.addSubview(manufacturerLabel)
        contentView.addSubview(sizeLabel)
        contentView.addSubview(sizeStackView)
        contentView.addSubview(colorLabel)
        contentView.addSubview(colorStackView)
    }

    func configureLayout() {
        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        materialLabel.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        countryLabel.snp.makeConstraints {
            $0.top.equalTo(materialLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        manufacturerLabel.snp.makeConstraints {
            $0.top.equalTo(countryLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        sizeLabel.snp.makeConstraints {
            $0.top.equalTo(manufacturerLabel.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        sizeStackView.snp.makeConstraints {
            $0.top.equalTo(sizeLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
            $0.height.equalTo(40)
        }

        colorLabel.snp.makeConstraints {
            $0.top.equalTo(sizeStackView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        colorStackView.snp.makeConstraints {
            $0.top.equalTo(colorLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
            $0.height.equalTo(40)
        }
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
