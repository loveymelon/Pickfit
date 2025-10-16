//
//  MainTabBarController.swift
//  Pickfit
//
//  Created by 김진수 on 9/30/25.
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTabBar()
        setupViewControllers()
        setupNotifications()
    }

    /// 배지 업데이트 알림 구독
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUpdateChatBadge),
            name: .updateChatBadge,
            object: nil
        )

        print("📊 [MainTabBarController] Badge notification observer added")
    }

    /// 채팅 탭 배지 업데이트
    @objc private func handleUpdateChatBadge() {
        let totalCount = BadgeManager.shared.getTotalUnreadCount()

        // 채팅 탭은 index 2 (홈:0, 주문:1, 채팅:2, 마이:3)
        let chatTabIndex = 2

        DispatchQueue.main.async {
            if totalCount > 0 {
                self.tabBar.items?[chatTabIndex].badgeValue = "\(totalCount)"
                print("📊 [MainTabBarController] Chat tab badge updated: \(totalCount)")
            } else {
                self.tabBar.items?[chatTabIndex].badgeValue = nil
                print("📊 [MainTabBarController] Chat tab badge cleared")
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureTabBar() {
        tabBar.backgroundColor = .white
        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = .gray
    }

    private func setupViewControllers() {
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let orderHistoryVC = OrderHistoryViewController()
        let orderHistoryNav = UINavigationController(rootViewController: orderHistoryVC)
        orderHistoryNav.tabBarItem = UITabBarItem(
            title: "주문",
            image: UIImage(named: "OrderEmpty"),
            selectedImage: UIImage(named: "OrderFill")
        )

        let chatListVC = ChatListViewController()
        let chatListNav = UINavigationController(rootViewController: chatListVC)
        chatListNav.tabBarItem = UITabBarItem(
            title: "채팅",
            image: UIImage(named: "messageCircle"),
            selectedImage: UIImage(named: "messageCircle")
        )

        let myPageVC = MyPageViewController()
        let myPageNav = UINavigationController(rootViewController: myPageVC)
        myPageNav.tabBarItem = UITabBarItem(
            title: "마이",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [homeNav, orderHistoryNav, chatListNav, myPageNav]
    }
}
