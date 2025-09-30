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

        // 추후 추가될 탭들
        // let searchVC = SearchViewController()
        // let searchNav = UINavigationController(rootViewController: searchVC)
        // searchNav.tabBarItem = UITabBarItem(title: "검색", image: UIImage(systemName: "magnifyingglass"), selectedImage: nil)

        // let profileVC = ProfileViewController()
        // let profileNav = UINavigationController(rootViewController: profileVC)
        // profileNav.tabBarItem = UITabBarItem(title: "마이", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))

        viewControllers = [homeNav]
    }
}