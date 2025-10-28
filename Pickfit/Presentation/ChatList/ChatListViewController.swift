//
//  ChatListViewController.swift
//  Pickfit
//
//  Created by 김진수 on 10/11/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

final class ChatListViewController: BaseViewController<ChatListView> {

    private let chatReactor = ChatListReactor()
    private let disposeBag = DisposeBag()
    private var isInitialLoad = true  // 처음 로드인지 판단

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupPushNotificationObserver()
        setupPrefetching()

        print("📱 [ChatList] viewDidLoad called")
        chatReactor.action.onNext(.viewDidLoad)
    }

    private func setupPrefetching() {
        // UITableView Prefetching 활성화 (화면에 보이는 cell + 여유분 자동 관리)
        mainView.tableView.prefetchDataSource = self
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        print("📱 [ChatList] viewIsAppearing - fetching latest chat list")
        print("📱 [ChatList] Current reactor state - rooms: \(chatReactor.currentState.allChatRooms.count), loading: \(chatReactor.currentState.isLoading)")
        chatReactor.action.onNext(.viewIsAppearing)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupNavigationBar() {
        // 네비게이션 바 숨김
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupPushNotificationObserver() {
        // 채팅 푸시 알림 수신 시 목록 갱신
        NotificationCenter.default.rx.notification(.chatPushReceived)
            .take(until: self.rx.deallocated)  // VC가 해제될 때까지만
            .subscribe(onNext: { [weak self] notification in
                print("📬 [ChatList] Push notification received - refreshing chat list")
                if let roomId = notification.userInfo?["roomId"] as? String {
                    print("📬 [ChatList] RoomId from push: \(roomId)")
                }
                self?.chatReactor.action.onNext(.receivedPushNotification)
            })
            .disposed(by: disposeBag)
    }

    override func bind() {
        bindAction()
        bindState()
    }

    private func bindAction() {
        // Pull to Refresh
        mainView.refreshControl.rx.controlEvent(.valueChanged)
            .map { ChatListReactor.Action.refresh }
            .bind(to: chatReactor.action)
            .disposed(by: disposeBag)

        // 전체 버튼
        mainView.allChatsButton.rx.tap
            .map { ChatListReactor.Action.changeFilter(.all) }
            .bind(to: chatReactor.action)
            .disposed(by: disposeBag)

        // 안읽음 버튼
        mainView.unreadChatsButton.rx.tap
            .map { ChatListReactor.Action.changeFilter(.unread) }
            .bind(to: chatReactor.action)
            .disposed(by: disposeBag)

        // Cell Selection
        mainView.tableView.rx.itemSelected
            .withLatestFrom(chatReactor.state.map { $0.filteredChatRooms }) { indexPath, rooms in
                rooms[indexPath.row]
            }
            .subscribe(onNext: { [weak self] chatRoom in
                self?.showChatDetail(chatRoom)
            })
            .disposed(by: disposeBag)
    }

    private func bindState() {
        // Filtered Chat Rooms
        chatReactor.state
            .map { $0.filteredChatRooms }
            .do(onNext: { rooms in
                print("🔄 [ChatList VC] Filtered chat rooms updated: \(rooms.count) items")
                if let first = rooms.first {
                    print("🔄 [ChatList VC] First room lastChat: \(first.lastChat?.content ?? "nil")")
                }
            })
            // distinctUntilChanged 제거 - 항상 최신 데이터로 업데이트
            .bind(to: mainView.tableView.rx.items(
                cellIdentifier: ChatListCell.identifier,
                cellType: ChatListCell.self
            )) { [weak self] index, chatRoom, cell in
                guard let self = self else { return }
                print("🔄 [ChatList VC] Configuring cell \(index): \(chatRoom.roomId), isInitialLoad: \(self.isInitialLoad)")
                cell.configure(with: chatRoom, isInitialLoad: self.isInitialLoad)

                // 첫 로드 후에는 false로 설정
                if self.isInitialLoad && index == 0 {
                    DispatchQueue.main.async {
                        self.isInitialLoad = false
                    }
                }
            }
            .disposed(by: disposeBag)

        // Filter Button UI Update
        chatReactor.state
            .map { $0.currentFilter }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] filter in
                self?.updateFilterButtons(filter)
            })
            .disposed(by: disposeBag)

        // Empty State
        chatReactor.state
            .map { $0.filteredChatRooms.isEmpty && !$0.isLoading }
            .do(onNext: { isEmpty in
                print("🔄 [ChatList VC] Empty state: \(isEmpty)")
            })
            .distinctUntilChanged()
            .bind(onNext: mainView.showEmpty(_:))
            .disposed(by: disposeBag)

        // Loading (Refresh Control)
        chatReactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .bind(to: mainView.refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        // Error
        chatReactor.state
            .compactMap { $0.errorMessage }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] message in
                self?.showAlert(message: message)
            })
            .disposed(by: disposeBag)
    }

    private func updateFilterButtons(_ filter: ChatListReactor.ChatFilter) {
        switch filter {
        case .all:
            mainView.allChatsButton.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
            mainView.allChatsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            mainView.allChatsButton.setTitleColor(.white, for: .normal)

            mainView.unreadChatsButton.backgroundColor = .clear
            mainView.unreadChatsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            mainView.unreadChatsButton.setTitleColor(.white.withAlphaComponent(0.6), for: .normal)

        case .unread:
            mainView.unreadChatsButton.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
            mainView.unreadChatsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            mainView.unreadChatsButton.setTitleColor(.white, for: .normal)

            mainView.allChatsButton.backgroundColor = .clear
            mainView.allChatsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            mainView.allChatsButton.setTitleColor(.white.withAlphaComponent(0.6), for: .normal)
        }
    }

    private func showChatDetail(_ chatRoom: ChatRoomEntity) {
        print("👆 [ChatList] Selected chat room: \(chatRoom.roomId)")

        // 현재 로그인한 사용자 ID 가져오기
        let currentUserId = KeychainAuthStorage.shared.readUserId() ?? ""

        // 상대방 참여자 찾기 (현재 사용자가 아닌 참여자)
        guard let otherParticipant = chatRoom.participants.first(where: { $0.userId != currentUserId }) else {
            print("❌ [ChatList] No other participant found")
            return
        }

        // 채팅 화면으로 네비게이션
        let chatVC = ChatViewController(roomInfo: (
            roomId: chatRoom.roomId,
            nickname: otherParticipant.nick,
            profileImageUrl: otherParticipant.profileImage
        ))

        navigationController?.pushViewController(chatVC, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension ChatListViewController: UITableViewDataSourcePrefetching {
    /// 화면에 보이기 전 미리 데이터 준비 (스크롤 성능 향상)
    /// - Note: UITableView가 자동으로 화면에 보이는 cell + 여유분을 prefetch함
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Prefetch는 안읽은 개수 API 호출에 사용되지 않음
        // Cell의 configure()에서 필요시 자동으로 API 호출됨
        // 이 메서드는 미래 확장을 위해 남겨둠
    }

    /// Prefetch 취소 (스크롤 방향이 바뀌어서 필요 없어진 경우)
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        // 필요시 구현
    }
}
