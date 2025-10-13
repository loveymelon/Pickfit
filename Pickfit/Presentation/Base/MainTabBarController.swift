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
            image: UIImage(named: "orderEmpty"),
            selectedImage: UIImage(named: "orderFill")
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
