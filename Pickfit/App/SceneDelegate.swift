//
//  SceneDelegate.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)

        // 토큰 확인 후 초기 화면 설정
        Task {
            let hasToken = await KeychainAuthStorage.shared.readAccess() != nil

            await MainActor.run {
                if hasToken {
                    // 토큰이 있으면 탭바로
                    window?.rootViewController = MainTabBarController()
                } else {
                    // 토큰이 없으면 로그인 화면으로
                    window?.rootViewController = LoginViewController()
                }
                window?.makeKeyAndVisible()
            }
        }

        // 로그아웃 Notification 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigateToLogin),
            name: .navigateToLogin,
            object: nil
        )

        // 채팅방 열기 구독 (푸시 알림 탭 시)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenChatRoom(_:)),
            name: .openChatRoom,
            object: nil
        )
    }

    @objc private func handleNavigateToLogin() {
        guard let window = window else { return }
        window.rootViewController = LoginViewController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }

    /// 특정 채팅방 열기 (푸시 알림 탭 시 또는 In-App Banner 탭 시)
    @objc private func handleOpenChatRoom(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let roomId = userInfo["roomId"] as? String else {
            print("⚠️ [SceneDelegate] Invalid roomId")
            return
        }

        print("📱 [SceneDelegate] Opening chat room: \(roomId)")
        openChatRoom(roomId: roomId)
    }

    /// 채팅방 열기 실제 구현
    private func openChatRoom(roomId: String) {
        guard let window = window,
              let tabBarController = window.rootViewController as? MainTabBarController else {
            print("⚠️ [SceneDelegate] TabBarController not found")
            return
        }

        // TODO: roomId로 채팅방 정보 조회
        // 실제 구현에서는 ChatRepository를 통해 채팅방 정보를 가져와야 함
        // 여기서는 간단하게 ChatListViewController로 이동 후 해당 방 열기

        // 1. 채팅 탭으로 이동 (index 2)
        tabBarController.selectedIndex = 2

        // 2. Navigation Stack 확인
        if let navigationController = tabBarController.selectedViewController as? UINavigationController {
            // 3. 이미 채팅방 화면이 열려있으면 pop
            if navigationController.viewControllers.count > 1 {
                navigationController.popToRootViewController(animated: false)
            }

            // 4. 채팅방 열기 (실제로는 ChatRepository로 방 정보 조회 필요)
            // 임시로 roomId만 전달
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // TODO: 실제 구현에서는 채팅방 정보를 가져와서 ChatViewController를 present
                print("📱 [SceneDelegate] Room \(roomId) should be opened here")
                // let chatVC = ChatViewController(roomInfo: ...)
                // navigationController.pushViewController(chatVC, animated: true)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        NotificationCenter.default.removeObserver(self)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

