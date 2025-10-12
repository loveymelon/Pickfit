//
//  ChatListViewController.swift
//  Pickfit
//
//  Created by Claude on 10/11/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

final class ChatListViewController: BaseViewController<ChatListView> {

    private let chatReactor = ChatListReactor()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()

        print("📱 [ChatList] viewDidLoad called")
        // 즉시 데이터 로드 트리거
        chatReactor.action.onNext(.viewDidLoad)
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
            })
            .distinctUntilChanged { $0.count == $1.count }
            .bind(to: mainView.tableView.rx.items(
                cellIdentifier: ChatListCell.identifier,
                cellType: ChatListCell.self
            )) { index, chatRoom, cell in
                print("🔄 [ChatList VC] Configuring cell \(index): \(chatRoom.roomId)")
                cell.configure(with: chatRoom)
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
        let currentUserId = KeychainAuthStorage.shared.readUserIdSync() ?? ""

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
