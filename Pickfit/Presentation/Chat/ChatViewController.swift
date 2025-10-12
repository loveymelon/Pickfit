//
//  ChatViewController.swift
//  Pickfit
//
//  Created by Claude on 10/12/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

final class ChatViewController: BaseViewController<ChatView>, View {

    var disposeBag = DisposeBag()
    private let roomInfo: (roomId: String, nickname: String, profileImageUrl: String?)

    init(roomInfo: (roomId: String, nickname: String, profileImageUrl: String?)) {
        self.roomInfo = roomInfo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupKeyboardHandling()
        hideCartButton() // 채팅 화면에서는 장바구니 버튼 숨김

        // Reactor 생성 및 할당
        self.reactor = ChatReactor(roomId: roomInfo.roomId)

        // 뷰에 채팅방 정보 설정
        mainView.configure(nickname: roomInfo.nickname, profileImageUrl: roomInfo.profileImageUrl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func setupTableView() {
        mainView.tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        mainView.tableView.dataSource = self
        mainView.tableView.delegate = self
        mainView.tableView.rowHeight = UITableView.automaticDimension
        mainView.tableView.estimatedRowHeight = 60
    }

    private func setupKeyboardHandling() {
        // 키보드 나타날 때
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, isShowing: true)
        }

        // 키보드 사라질 때
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, isShowing: false)
        }
    }

    private func handleKeyboard(notification: Notification, isShowing: Bool) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let keyboardHeight = isShowing ? keyboardFrame.height : 0
        let bottomPadding = view.safeAreaInsets.bottom

        UIView.animate(withDuration: duration) {
            // inputContainerView의 bottom constraint를 키보드 높이만큼 조정
            self.mainView.layoutIfNeeded()
        }

        // 키보드가 나타날 때 테이블뷰를 맨 아래로 스크롤
        if isShowing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.scrollToBottom(animated: true)
            }
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard let reactor = reactor,
              !reactor.currentState.messages.isEmpty else {
            return
        }

        let lastIndexPath = IndexPath(row: reactor.currentState.messages.count - 1, section: 0)
        mainView.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
    }

    func bind(reactor: ChatReactor) {
        // MARK: - Action

        // View가 로드되면 초기 메시지 로드 및 Socket 연결
        rx.viewDidLoad
            .map { ChatReactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 뒤로가기 버튼
        mainView.backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        // 메시지 입력 텍스트 변경
        mainView.messageTextView.rx.text.orEmpty
            .distinctUntilChanged()
            .map { ChatReactor.Action.updateMessageText($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 전송 버튼 탭
        mainView.sendButton.rx.tap
            .withLatestFrom(mainView.messageTextView.rx.text.orEmpty)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .do(onNext: { [weak self] _ in
                // 메시지 전송 후 텍스트뷰 초기화
                self?.mainView.messageTextView.text = ""
                reactor.action.onNext(.updateMessageText(""))
            })
            .map { ChatReactor.Action.sendMessage($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // MARK: - State

        // 메시지 목록 변경 시 테이블뷰 리로드
        reactor.state.map { $0.messages }
            .distinctUntilChanged { $0.count == $1.count }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.mainView.tableView.reloadData()
                self?.scrollToBottom(animated: true)
            })
            .disposed(by: disposeBag)

        // 전송 버튼 활성화 상태
        reactor.state.map { $0.isSendButtonEnabled }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isEnabled in
                self?.mainView.updateSendButton(isEnabled: isEnabled)
            })
            .disposed(by: disposeBag)

        // 에러 처리
        reactor.state.compactMap { $0.errorMessage }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                print("❌ [ChatViewController] Error: \(error)")
                // TODO: 에러 토스트 메시지 표시
            })
            .disposed(by: disposeBag)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("🗑️ [ChatViewController] Deallocated")
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reactor?.currentState.messages.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.identifier, for: indexPath) as? ChatMessageCell,
              let message = reactor?.currentState.messages[indexPath.row] else {
            return UITableViewCell()
        }

        cell.configure(with: message)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ChatViewController: UITableViewDelegate {
    // 스크롤 시 키보드 숨김
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        mainView.messageTextView.resignFirstResponder()
    }
}
