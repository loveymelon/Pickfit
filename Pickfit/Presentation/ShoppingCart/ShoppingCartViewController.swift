//
//  ShoppingCartViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

final class ShoppingCartViewController: BaseViewController<ShoppingCartView> {
    var disposeBag = DisposeBag()

    private let reactor = ShoppingCartReactor()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "장바구니"
        hideCartButton() // 장바구니 화면에서는 우측 상단 버튼 숨김
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let backButton = UIBarButtonItem(
            image: UIImage(named: "chevron"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
        navigationItem.hidesBackButton = true
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    override func bind() {
        super.bind()

        // MARK: - Action
        rx.viewDidLoad
            .map { ShoppingCartReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 주문하기 버튼
        mainView.purchaseButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handlePurchase()
            })
            .disposed(by: disposeBag)

        // MARK: - State
        // TableView 데이터 바인딩
        reactor.state.map { $0.cartItems }
            .bind(to: mainView.tableView.rx.items(
                cellIdentifier: CartItemCell.identifier,
                cellType: CartItemCell.self
            )) { [weak self] (index: Int, item: CartItem, cell: CartItemCell) -> Void in
                self?.configureCell(cell, at: index, with: item)
            }
            .disposed(by: disposeBag)

        // 주문하기 버튼 업데이트
        reactor.state.map { $0.totalPrice }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] totalPrice in
                self?.mainView.updatePurchaseButton(totalPrice: totalPrice)
            })
            .disposed(by: disposeBag)

        // 빈 화면 처리
        reactor.state.map { $0.cartItems.isEmpty }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isEmpty in
                self?.mainView.showEmpty(isEmpty)
            })
            .disposed(by: disposeBag)
    }

    private func configureCell(_ cell: CartItemCell, at index: Int, with item: CartItem) {
        cell.configure(with: item)

        // 수량 변경
        cell.onQuantityChanged = { [weak self] newQuantity in
            self?.reactor.action.onNext(.updateQuantity(index, newQuantity))
        }

        // 삭제
        cell.onDelete = { [weak self] in
            self?.reactor.action.onNext(.deleteItem(index))
        }
    }

    private func handlePurchase() {
        let cartItems = reactor.currentState.cartItems
        let totalPrice = reactor.currentState.totalPrice

        // 1. 빈 장바구니 체크
        if cartItems.isEmpty {
            showAlert(message: "장바구니가 비어있습니다")
            return
        }

        // 2. storeId 추출 (첫 번째 아이템)
        guard let storeId = cartItems.first?.menu.storeId else {
            showAlert(message: "상품 정보를 찾을 수 없습니다")
            return
        }

        // 3. OrderMenuDTO 배열 생성
        let orderMenuList = cartItems.map { item in
            OrderMenuDTO(menuId: item.menu.menuId, quantity: item.quantity)
        }

        // 4. 주문명 생성 (첫 번째 메뉴명 + 외 N개)
        let orderName: String
        if cartItems.count == 1 {
            orderName = cartItems[0].menu.name
        } else {
            orderName = "\(cartItems[0].menu.name) 외 \(cartItems.count - 1)개"
        }

        print("🛒 [주문하기] 시작 - \(orderName), 총액: \(totalPrice)원")

        // 5. 비동기 작업 실행
        Task { @MainActor in
            await processOrder(
                storeId: storeId,
                orderMenuList: orderMenuList,
                totalPrice: totalPrice,
                orderName: orderName
            )
        }
    }

    @MainActor
    private func processOrder(
        storeId: String,
        orderMenuList: [OrderMenuDTO],
        totalPrice: Int,
        orderName: String
    ) async {
        do {
            // Step 1: 주문 생성 API 호출
            print("📡 [Step 1] 주문 생성 API 호출...")
            let orderRepository = OrderRepository()
            let orderEntity = try await orderRepository.createOrder(
                storeId: storeId,
                orderMenuList: orderMenuList,
                totalPrice: totalPrice
            )
            print("✅ [Step 1] 주문 생성 완료 - orderCode: \(orderEntity.orderCode)")

            // Step 2: 포트원 결제 실행
            print("💳 [Step 2] 포트원 결제 실행...")
            let impUid = try await executePayment(
                orderCode: orderEntity.orderCode,
                amount: totalPrice,
                name: orderName
            )
            print("✅ [Step 2] 결제 완료 - imp_uid: \(impUid)")

            // Step 3: 결제 검증 API 호출
            print("🔍 [Step 3] 결제 검증 API 호출...")
            _ = try await orderRepository.validatePayment(impUid: impUid)
            print("✅ [Step 3] 결제 검증 완료")

            // Step 4: 성공 처리
            handlePaymentSuccess()

        } catch {
            // 에러 처리
            handlePaymentError(error)
        }
    }

    private func executePayment(
        orderCode: String,
        amount: Int,
        name: String
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            IamportManager.shared.requestPayment(
                from: self,
                orderCode: orderCode,
                amount: amount,
                name: name
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func handlePaymentSuccess() {
        print("🎉 주문 완료!")

        // 장바구니 비우기
        CartManager.shared.clearCart()

        // 성공 알림 표시
        let alert = UIAlertController(
            title: "주문 완료",
            message: "주문이 성공적으로 완료되었습니다",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            // 주문 내역 화면으로 이동
            self?.navigateToOrderHistory()
        })
        present(alert, animated: true)
    }

    private func handlePaymentError(_ error: Error) {
        print("❌ 주문 실패: \(error.localizedDescription)")

        let errorMessage: String
        if let iamportError = error as? IamportError {
            errorMessage = iamportError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }

        showAlert(message: errorMessage)
    }

    private func navigateToOrderHistory() {
        // 1. 현재 navigationController의 root로 돌아감 (홈 화면)
        navigationController?.popToRootViewController(animated: false)

        // 2. TabBarController의 주문 탭(index 1) 선택
        if let tabBarController = navigationController?.tabBarController {
            tabBarController.selectedIndex = 1 // 주문 탭
            print("✅ 주문 탭으로 이동")
        } else {
            print("⚠️ TabBarController를 찾을 수 없음")
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
