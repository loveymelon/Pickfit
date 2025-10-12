//
//  IamportManager.swift
//  Pickfit
//
//  Created by 김진수 on 10/9/25.
//

import UIKit
import iamport_ios

final class IamportManager {
    static let shared = IamportManager()

    private init() {}
    
    func requestPayment(
        from viewController: UIViewController,
        orderCode: String,
        amount: Int,
        name: String,
        buyerName: String? = "김진수",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Iamport 결제 데이터 구성
        let payment = IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
            merchant_uid: orderCode,  // 주문번호를 merchant_uid로 사용
            amount: String(amount)
        ).then {
            $0.pay_method = PayMethod.card.rawValue
            $0.name = name
            $0.buyer_name = buyerName
            $0.app_scheme = "pickfit"  // URL Scheme
        }

        // 포트원 결제 실행
        guard let navController = viewController.navigationController else {
            completion(.failure(IamportError.noNavigationController))
            return
        }

        Iamport.shared.payment(
            navController: navController,
            userCode: APIKey.iamportUserCode,
            payment: payment
        ) { response in
            if let response = response {
                self.handlePaymentResponse(response, completion: completion)
            } else {
                completion(.failure(IamportError.noResponse))
            }
        }
    }

    /// 결제 응답 처리
    private func handlePaymentResponse(
        _ response: IamportResponse,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        if response.success == true,
           let impUid = response.imp_uid {
            // 결제 성공 - imp_uid 반환
            completion(.success(impUid))
        } else {
            // 결제 실패
            let errorMessage = response.error_msg ?? "결제에 실패했습니다"
            completion(.failure(IamportError.paymentFailed(errorMessage)))
        }
    }
}

// MARK: - Error Types
enum IamportError: LocalizedError {
    case noNavigationController
    case noResponse
    case paymentFailed(String)

    var errorDescription: String? {
        switch self {
        case .noNavigationController:
            return "NavigationController를 찾을 수 없습니다"
        case .noResponse:
            return "결제 응답을 받지 못했습니다"
        case .paymentFailed(let message):
            return message
        }
    }
}
