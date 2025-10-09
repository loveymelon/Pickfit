//
//  StoreDetailView.swift
//  Pickfit
//
//  Created by 김진수 on 10/4/25.
//

import UIKit
import SnapKit
import Then

final class StoreDetailView: BaseView {
    let collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()).then {
        $0.backgroundColor = .white
        $0.register(StoreDetailCell.self, forCellWithReuseIdentifier: StoreDetailCell.identifier)
        $0.register(StoreProductCell.self, forCellWithReuseIdentifier: StoreProductCell.identifier)
        $0.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        $0.register(StoreHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StoreHeaderView.reuseID)
    }

    // 장바구니 하단 버튼 컨테이너
    let cartBottomView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowOffset = CGSize(width: 0, height: -3)
        $0.layer.shadowRadius = 10
        $0.isHidden = true // 초기에는 숨김
    }

    let purchaseButton = UIButton(type: .system).then {
        $0.setTitle("장바구니 보기", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        $0.backgroundColor = .black
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 8
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(collectionView)
        addSubview(cartBottomView)
        cartBottomView.addSubview(purchaseButton)
    }

    override func configureLayout() {
        cartBottomView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
            $0.height.equalTo(80)
        }

        purchaseButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }

        collectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // 상단에만 그림자가 보이도록 shadowPath 설정
        let shadowRect = CGRect(x: 0, y: -10, width: cartBottomView.bounds.width, height: 10)
        cartBottomView.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
    }

    override func configureUI() {
        super.configureUI()
        // CollectionView가 safeArea 무시하고 최상단까지 올라가도록 설정
        collectionView.contentInsetAdjustmentBehavior = .never
    }

    // 장바구니 버튼 표시/숨김
    func setCartBottomViewVisible(_ visible: Bool) {
        cartBottomView.isHidden = !visible

        // collectionView의 bottom constraint 재설정
        collectionView.snp.remakeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            if visible {
                $0.bottom.equalTo(cartBottomView.snp.top)
            } else {
                $0.bottom.equalToSuperview()
            }
        }

        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }

    // 장바구니 정보 업데이트 (수량, 총 금액)
    func updateCartInfo(totalQuantity: Int, totalPrice: Int) {
        let formattedPrice = formatPrice(totalPrice)
        purchaseButton.setTitle("장바구니 보기 (\(totalQuantity)개) · \(formattedPrice)원", for: .normal)
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}
