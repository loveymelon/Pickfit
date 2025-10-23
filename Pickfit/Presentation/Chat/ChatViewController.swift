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
import PhotosUI

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
        setupTextView()
        hideCartButton() // 채팅 화면에서는 장바구니 버튼 숨김

        // Reactor 생성 및 할당
        let chatReactor = ChatReactor(roomId: roomInfo.roomId)
        self.reactor = chatReactor

        // 뷰에 채팅방 정보 설정
        mainView.configure(nickname: roomInfo.nickname, profileImageUrl: roomInfo.profileImageUrl)

        // 즉시 초기 데이터 로드 및 소켓 연결 시작
        print("🚀 [ChatViewController] Triggering viewDidLoad action")
        chatReactor.action.onNext(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        tabBarController?.tabBar.isHidden = true

        // ✅ 중요: 현재 채팅방을 "활성 방"으로 등록
        // 이 방의 메시지는 알림이 표시되지 않음
        ChatStateManager.shared.setActiveRoom(roomInfo.roomId)
        print("📊 [ChatViewController] Active room set: \(roomInfo.roomId)")

        // 배지 초기화: 이 방의 읽지 않은 메시지 개수를 0으로
        BadgeManager.shared.clearUnreadCount(for: roomInfo.roomId)

        // 탭바 배지 업데이트
        if let tabBarController = tabBarController {
            let totalCount = BadgeManager.shared.getTotalUnreadCount()
            let chatTabIndex = 2 // 채팅 탭 인덱스 (MainTabBarController 구조에 맞게 조정)
            tabBarController.tabBar.items?[chatTabIndex].badgeValue = totalCount > 0 ? "\(totalCount)" : nil
            print("📊 [ChatViewController] Tab badge updated: \(totalCount)")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        tabBarController?.tabBar.isHidden = false

        // ✅ 마지막 메시지 ID 저장 (안읽은 개수 계산용)
        if let lastMessageId = ChatStorage.shared.fetchLastChatId(roomId: roomInfo.roomId) {
            ChatRoomStorage.shared.updateLastReadChatId(
                roomId: roomInfo.roomId,
                lastReadChatId: lastMessageId
            )
            print("📝 [ChatViewController] Saved lastReadChatId: \(lastMessageId) for room: \(roomInfo.roomId)")
        }

        // ✅ 중요: 채팅방을 나갈 때 "활성 방" 해제
        // 이제부터 이 방의 메시지는 알림이 표시됨
        ChatStateManager.shared.clearActiveRoom()
        print("📊 [ChatViewController] Active room cleared")
    }

    private func setupTableView() {
        mainView.tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        mainView.tableView.dataSource = self
        mainView.tableView.delegate = self
        mainView.tableView.rowHeight = UITableView.automaticDimension
        mainView.tableView.estimatedRowHeight = 60

        // 테이블뷰 탭 시 키보드 내리기 (주석처리)
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
//        tapGesture.cancelsTouchesInView = false
//        tapGesture.delegate = self
//        mainView.tableView.addGestureRecognizer(tapGesture)
    }

    private func setupTextView() {
        mainView.messageTextView.delegate = self
    }

//    @objc private func dismissKeyboard() {
//        print("⌨️ [Keyboard] Dismissing keyboard - tableView tapped")
//        view.endEditing(true)
//    }

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

        // tableView의 bottom contentInset 조정
        var contentInset = mainView.tableView.contentInset
        contentInset.bottom = keyboardHeight + 60 + 16 // 키보드 + inputContainer 높이 + 여유
        mainView.tableView.contentInset = contentInset
        mainView.tableView.scrollIndicatorInsets = contentInset

        // inputContainerView를 키보드 위로 이동
        UIView.animate(withDuration: duration) {
            self.mainView.inputContainerView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        } completion: { _ in
            // 키보드가 나타날 때 테이블뷰를 맨 아래로 스크롤
            if isShowing {
                self.scrollToBottom(animated: true)
            }
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard let reactor = reactor,
              !reactor.currentState.messages.isEmpty else {
            print("⚠️ [ScrollToBottom] No messages or reactor is nil")
            return
        }

        let lastIndexPath = IndexPath(row: reactor.currentState.messages.count - 1, section: 0)
        print("📜 [ScrollToBottom] Scrolling to index: \(lastIndexPath.row)")
        print("📜 [ScrollToBottom] TableView contentSize: \(mainView.tableView.contentSize)")
        print("📜 [ScrollToBottom] TableView frame: \(mainView.tableView.frame)")

        mainView.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
    }

    func bind(reactor: ChatReactor) {
        // MARK: - Action

        // View가 로드되면 초기 메시지 로드 및 Socket 연결
        // (viewDidLoad에서 직접 호출하므로 여기서는 제거)
//        rx.viewDidLoad
//            .map { ChatReactor.Action.viewDidLoad }
//            .bind(to: reactor.action)
//            .disposed(by: disposeBag)

        // 뒤로가기 버튼
        mainView.backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        // 첨부 버튼 (파일/사진 선택)
        mainView.attachButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showAttachmentOptions()
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
            .do(onNext: { text in
                print("📤 [Send] Sending message: \(text)")
            })
            .do(onNext: { [weak self] _ in
                // 메시지 전송 후 텍스트뷰 초기화
                self?.mainView.messageTextView.text = ""
                reactor.action.onNext(.updateMessageText(""))
            })
            .map { ChatReactor.Action.sendMessage($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // MARK: - State

        // 메시지 목록 변경 시 테이블뷰 리로드 (pagination이 아닌 경우)
        reactor.state.map { $0.messages }
            .distinctUntilChanged { $0.count == $1.count }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] messages in
                guard let self = self, let reactor = self.reactor else { return }

                // prependedCount가 0인 경우에만 reloadData (초기 로드, 새 메시지 추가)
                // prependedCount > 0이면 insertRows 구독에서 처리
                if reactor.currentState.prependedCount == 0 {
                    print("📊 [ChatViewController] Messages changed (not pagination): \(messages.count)")
                    messages.forEach { msg in
                        print("  - [\(msg.isMyMessage ? "ME" : "OTHER")] \(msg.content)")
                    }
                    self.mainView.tableView.reloadData()

                    // 초기 로드나 새 메시지 추가 시 스크롤
                    DispatchQueue.main.async {
                        self.scrollToBottom(animated: false)
                    }
                } else {
                    print("📊 [ChatViewController] Messages changed but prependedCount > 0, skipping reloadData")
                }
            })
            .disposed(by: disposeBag)

        // Pagination을 위한 prependedCount 구독 (insertRows 사용)
        reactor.state.map { $0.prependedCount }
            .distinctUntilChanged()
            .filter { $0 > 0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                guard let self = self else { return }

                print("📊 [ChatViewController] prependedCount: \(count) - using insertRows")

                // 스크롤 위치 저장 (insertRows 전)
                let contentOffset = self.mainView.tableView.contentOffset
                let contentHeight = self.mainView.tableView.contentSize.height

                // insertRows로 배열 앞에 추가
                let indexPaths = (0..<count).map { IndexPath(row: $0, section: 0) }

                self.mainView.tableView.performBatchUpdates {
                    self.mainView.tableView.insertRows(at: indexPaths, with: .none)
                } completion: { _ in
                    // 스크롤 위치 조정 (새로 추가된 셀들의 높이만큼 보정)
                    let newContentHeight = self.mainView.tableView.contentSize.height
                    let heightDiff = newContentHeight - contentHeight
                    self.mainView.tableView.setContentOffset(
                        CGPoint(x: contentOffset.x, y: contentOffset.y + heightDiff),
                        animated: false
                    )

                    print("📊 [ChatViewController] insertRows completed, contentOffset adjusted by \(heightDiff)")
                }

                // prependedCount 초기화
                reactor.action.onNext(.resetPrependedCount)
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

        // 선택된 파일 상태 구독 (프리뷰 업데이트)
        // ⚠️ 주의: uploadFiles/PHPicker에서 이미 프리뷰를 업데이트하므로
        // 여기서는 파일 제거/전송 완료 시 프리뷰를 숨기는 용도로만 사용
        reactor.state.map { $0.selectedImageDataList }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] imageDataList in
                guard let self = self else { return }
                print("🖼️ [ChatViewController] Selected files state updated: \(imageDataList.count)")

                // 파일이 없으면 프리뷰 숨김 (전송 완료 후)
                if imageDataList.isEmpty {
                    self.selectedFileData.removeAll()
                    self.mainView.imagePreviewView.updateFiles([]) { _ in }
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Image Picker

    private func showAttachmentOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // 사진 선택
        let photoAction = UIAlertAction(title: "사진 전송", style: .default) { [weak self] _ in
            self?.presentImagePicker()
        }

        // 파일 선택
        let fileAction = UIAlertAction(title: "파일 전송", style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        }

        // 취소
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(photoAction)
        alert.addAction(fileAction)
        alert.addAction(cancelAction)

        // iPad 대응
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = mainView.attachButton
            popoverController.sourceRect = mainView.attachButton.bounds
        }

        present(alert, animated: true)
    }

    private func presentImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 5  // 최대 5개
        configuration.filter = .images    // 이미지만 선택

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentDocumentPicker() {
        // API 지원 확장자: jpg, png, jpeg, gif, pdf
        let supportedTypes: [UTType] = [
            .jpeg,  // jpg, jpeg
            .png,
            .gif,
            .pdf
        ]

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
    }

    private func presentPDFViewer(urlString: String) {
        print("📄 [PDF Viewer] Opening: \(urlString)")

        // URL 문자열을 URL로 변환
        var pdfURL: URL?

        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            // 원격 URL
            pdfURL = URL(string: urlString)
        } else if urlString.hasPrefix("/") {
            // 서버 상대 경로 -> 절대 URL로 변환
            // APIKey.baseURL을 사용 (ChatMessageCell과 동일한 방식)
            let fullURLString = APIKey.baseURL + urlString
            pdfURL = URL(string: fullURLString)
            print("🔗 [PDF Viewer] Constructed URL: \(fullURLString)")
        } else {
            // 로컬 파일 경로
            pdfURL = URL(fileURLWithPath: urlString)
        }

        guard let url = pdfURL else {
            print("❌ [PDF Viewer] Invalid URL: \(urlString)")
            return
        }

        print("✅ [PDF Viewer] Final URL: \(url.absoluteString)")

        let fileName = (urlString as NSString).lastPathComponent
        let pdfViewerVC = PDFViewerViewController(pdfURL: url, fileName: fileName)
        pdfViewerVC.modalPresentationStyle = .fullScreen
        present(pdfViewerVC, animated: true)
    }

    // 파일 타입과 데이터를 함께 저장하는 구조체
    private struct FileData {
        let data: Data
        let fileName: String
        let isPDF: Bool
    }

    private var selectedFileData: [FileData] = []

    private func uploadFiles(_ urls: [URL]) {
        guard let reactor = reactor else { return }

        var fileDataList: [FileData] = []

        for url in urls {
            // Security-scoped resource 접근 시작 (asCopy: false이므로 필수)
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ [File Upload] Cannot access file: \(url.lastPathComponent)")
                continue
            }

            do {
                // 직접 파일 Data 읽기
                let fileData = try Data(contentsOf: url)
                let fileName = url.lastPathComponent

                // UTType과 파일명 둘 다 체크해서 PDF 감지
                var isPDF = false

                // 1. UTType으로 체크 (가장 정확)
                if let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
                    isPDF = contentType.conforms(to: .pdf)
                    print("🔍 [File Upload] UTType check: \(contentType.identifier), isPDF: \(isPDF)")
                }

                // 2. UTType 실패 시 확장자로 체크
                if !isPDF {
                    isPDF = fileName.lowercased().hasSuffix(".pdf")
                    print("🔍 [File Upload] Extension check: \(fileName), isPDF: \(isPDF)")
                }

                // 3. Data의 매직 넘버로 체크 (PDF는 %PDF로 시작)
                if !isPDF && fileData.count > 4 {
                    let header = fileData.prefix(4)
                    if let headerString = String(data: header, encoding: .ascii), headerString == "%PDF" {
                        isPDF = true
                        print("🔍 [File Upload] Magic number check: Found PDF signature")
                    }
                }

                fileDataList.append(FileData(data: fileData, fileName: fileName, isPDF: isPDF))
                print("✅ [File Upload] File loaded: \(fileName), Size: \(fileData.count) bytes, isPDF: \(isPDF)")
            } catch {
                print("❌ [File Upload] Failed to load file: \(error)")
            }

            // 접근 종료
            url.stopAccessingSecurityScopedResource()
        }

        if !fileDataList.isEmpty {
            selectedFileData = fileDataList
            print("✅ [File Upload] \(fileDataList.count) files loaded, updating preview")

            // 프리뷰 업데이트
            updateFilePreview()

            // Reactor에 Data만 전달 (업로드는 Reactor에서 selectedFileData 사용)
            let dataList = fileDataList.map { $0.data }
            reactor.action.onNext(.selectImages(dataList))
        }
    }

    private func updateFilePreview() {
        guard !selectedFileData.isEmpty else { return }

        // FileData → ImagePreviewView.FilePreviewType 변환
        var previewFiles: [ImagePreviewView.FilePreviewType] = []

        for fileData in selectedFileData {
            if fileData.isPDF {
                previewFiles.append(.pdf(fileData.data, fileName: fileData.fileName))
            } else {
                // 이미지로 변환
                if let image = UIImage(data: fileData.data) {
                    previewFiles.append(.image(image))
                }
            }
        }

        print("📄 [File Preview] Updating preview with \(previewFiles.count) files")

        // 프리뷰 업데이트
        mainView.imagePreviewView.updateFiles(previewFiles) { [weak self] index in
            self?.reactor?.action.onNext(.removeImage(index))
            // selectedFileData도 함께 제거
            self?.selectedFileData.remove(at: index)
            self?.updateFilePreview()
        }

        // 이미지 탭 콜백 설정
        mainView.imagePreviewView.onImageTapped = { [weak self] image in
            print("🖼️ [File Preview] Image tapped in preview")
            let imageViewerVC = ImageViewerViewController(image: image)
            self?.present(imageViewerVC, animated: true)
        }

        // PDF 탭 콜백 설정
        mainView.imagePreviewView.onPDFTapped = { [weak self] pdfData, fileName in
            print("📄 [File Preview] PDF tapped in preview: \(fileName)")
            self?.presentPDFViewerFromData(pdfData: pdfData, fileName: fileName)
        }
    }

    private func presentPDFViewerFromData(pdfData: Data, fileName: String) {
        // Data를 임시 파일로 저장
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tempURL)
            let pdfViewerVC = PDFViewerViewController(pdfURL: tempURL, fileName: fileName)
            pdfViewerVC.modalPresentationStyle = .fullScreen
            present(pdfViewerVC, animated: true)
        } catch {
            print("❌ [PDF Viewer] Failed to save temp file: \(error)")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("🗑️ [ChatViewController] Deallocated")
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = reactor?.currentState.messages.count ?? 0
        print("📊 [TableView] numberOfRows: \(count)")
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("📊 [TableView] cellForRowAt: \(indexPath.row)")

        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.identifier, for: indexPath) as? ChatMessageCell,
              let message = reactor?.currentState.messages[indexPath.row] else {
            print("❌ [TableView] Failed to dequeue cell or get message at \(indexPath.row)")
            return UITableViewCell()
        }

        // 시간 표시 여부 결정
        let showTime = shouldShowTime(at: indexPath)
        // 프로필 표시 여부 결정
        let showProfile = shouldShowProfile(at: indexPath)

        print("✅ [TableView] Configuring cell with: \(message.content), showTime: \(showTime), showProfile: \(showProfile)")
        cell.configure(with: message, showTime: showTime, showProfile: showProfile)

        // 이미지 탭 시 전체화면 뷰어 표시
        cell.onImageTapped = { [weak self] imageURL in
            let imageViewerVC = ImageViewerViewController(imageURL: imageURL)
            self?.present(imageViewerVC, animated: true)
        }

        // PDF 탭 시 PDF 뷰어 표시
        cell.onPDFTapped = { [weak self] pdfURLString in
            print("📞 [ChatViewController] onPDFTapped callback received: \(pdfURLString)")
            self?.presentPDFViewer(urlString: pdfURLString)
        }

        return cell
    }

    /// 시간을 표시할지 결정 (같은 사용자의 같은 시간대 마지막 메시지만 표시)
    private func shouldShowTime(at indexPath: IndexPath) -> Bool {
        guard let messages = reactor?.currentState.messages else {
            print("⚠️ [shouldShowTime] No messages")
            return true
        }

        // 마지막 메시지는 항상 시간 표시
        if indexPath.row == messages.count - 1 {
            print("✅ [shouldShowTime] Last message at \(indexPath.row) - show time")
            return true
        }

        let currentMessage = messages[indexPath.row]
        let nextMessage = messages[indexPath.row + 1]

        // 다음 메시지가 다른 사용자면 현재 메시지에 시간 표시
        if currentMessage.isMyMessage != nextMessage.isMyMessage {
            print("✅ [shouldShowTime] Row \(indexPath.row): Different user - show time")
            return true
        }

        // 같은 사용자이고, 같은 시간대면 시간 숨김
        let isSame = isSameMinute(currentMessage.createdAt, nextMessage.createdAt)
        print("🔍 [shouldShowTime] Row \(indexPath.row): Same user, isSameMinute=\(isSame), showTime=\(!isSame)")

        return !isSame
    }

    /// 프로필을 표시할지 결정 (상대방의 연속 메시지 중 첫 번째만 표시)
    private func shouldShowProfile(at indexPath: IndexPath) -> Bool {
        guard let messages = reactor?.currentState.messages else { return true }

        let currentMessage = messages[indexPath.row]

        // 내 메시지면 프로필 표시 안 함
        if currentMessage.isMyMessage {
            return false
        }

        // 첫 번째 메시지는 항상 프로필 표시
        if indexPath.row == 0 {
            return true
        }

        let previousMessage = messages[indexPath.row - 1]

        // 이전 메시지가 내 메시지면 현재 메시지는 프로필 표시
        if previousMessage.isMyMessage {
            return true
        }

        // 이전 메시지도 상대방 메시지면 프로필 숨김
        return false
    }

    /// 두 시간이 같은 분인지 확인
    private func isSameMinute(_ time1: String, _ time2: String) -> Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date1 = formatter.date(from: time1),
              let date2 = formatter.date(from: time2) else {
            print("❌ [isSameMinute] Failed to parse dates: \(time1), \(time2)")
            return false
        }

        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date2)

        let isSame = components1.year == components2.year &&
                     components1.month == components2.month &&
                     components1.day == components2.day &&
                     components1.hour == components2.hour &&
                     components1.minute == components2.minute

        print("🕐 [isSameMinute] \(components1.hour ?? 0):\(components1.minute ?? 0) vs \(components2.hour ?? 0):\(components2.minute ?? 0) → \(isSame)")

        return isSame
    }
}

// MARK: - UITableViewDelegate
extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let reactor = reactor else { return }

        // 이미 로딩 중이거나 메시지가 없으면 무시
        if reactor.currentState.isLoadingMore || reactor.currentState.messages.isEmpty {
            return
        }

        // 상단 근처까지 스크롤했는지 확인 (threshold: 100pt)
        // contentOffset.y가 작을수록 상단에 가까움
        if scrollView.contentOffset.y < 100 {
            print("📜 [ScrollView] Near top (offset: \(scrollView.contentOffset.y)), triggering pagination")
            reactor.action.onNext(.loadMoreMessages)
        }
    }
}

// MARK: - UITextViewDelegate
extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = min(max(size.height, 36), 100)

        // 스크롤 활성화 여부 결정
        textView.isScrollEnabled = newHeight >= 100

        // 높이 constraint 재설정
        textView.snp.remakeConstraints { make in
            make.leading.equalTo(mainView.attachButton.snp.trailing).offset(8)
            make.trailing.equalTo(mainView.sendButton.snp.leading).offset(-8)
            make.centerY.equalTo(mainView.attachButton)
            make.height.equalTo(newHeight)
        }

        // 애니메이션과 함께 레이아웃 업데이트
        UIView.animate(withDuration: 0.1) {
            self.view.layoutIfNeeded()
        }

        // 높이가 최대치에 도달하면 커서를 맨 아래로
        if newHeight >= 100 {
            let bottom = textView.contentSize.height - textView.bounds.size.height
            if bottom > 0 {
                textView.setContentOffset(CGPoint(x: 0, y: bottom), animated: false)
            }
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ChatViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            print("🖼️ [PHPicker] No images selected")
            return
        }

        print("🖼️ [PHPicker] Selected \(results.count) items")

        // 비동기로 이미지 로드
        var loadedImages: [UIImage] = []
        let dispatchGroup = DispatchGroup()

        for result in results {
            dispatchGroup.enter()

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                defer { dispatchGroup.leave() }

                if let error = error {
                    print("❌ [PHPicker] Failed to load image: \(error)")
                    return
                }

                if let image = object as? UIImage {
                    loadedImages.append(image)
                    print("✅ [PHPicker] Image loaded: \(image.size)")
                }
            }
        }

        // 모든 이미지 로드 완료 후 리사이징 → Reactor에 전달
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self, let reactor = self.reactor else { return }
            print("✅ [PHPicker] All images loaded: \(loadedImages.count)")

            // UIImage → 리사이징 → Data 변환
            let imageDataList = ImageResizer.resizeMultiple(
                images: loadedImages,
                maxDimension: 1280,
                compressionQuality: 0.7
            )

            print("✅ [PHPicker] Images resized: \(imageDataList.count)")

            // selectedFileData 업데이트 (이미지만 해당)
            self.selectedFileData = imageDataList.map { data in
                FileData(data: data, fileName: "image.jpg", isPDF: false)
            }

            // 프리뷰 업데이트
            self.updateFilePreview()

            // Reactor에 전달
            reactor.action.onNext(.selectImages(imageDataList))
        }
    }
}

// MARK: - UIDocumentPickerDelegate

extension ChatViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)

        guard !urls.isEmpty else {
            print("📄 [DocumentPicker] No files selected")
            return
        }

        print("📄 [DocumentPicker] Selected \(urls.count) files")

        let maxFileSize: Int64 = 5 * 1024 * 1024 // 5MB

        var validFiles: [URL] = []
        var oversizedFiles: [String] = []

        for url in urls {
            // 파일 접근 권한 획득
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ [DocumentPicker] Cannot access file: \(url.lastPathComponent)")
                continue
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = fileAttributes[.size] as? Int64 ?? 0

                print("📄 [DocumentPicker] File: \(url.lastPathComponent), Size: \(fileSize) bytes")

                if fileSize > maxFileSize {
                    let fileSizeMB = Double(fileSize) / (1024.0 * 1024.0)
                    oversizedFiles.append("\(url.lastPathComponent) (\(String(format: "%.1f", fileSizeMB))MB)")
                    print("❌ [DocumentPicker] File too large: \(url.lastPathComponent)")
                } else {
                    validFiles.append(url)
                }
            } catch {
                print("❌ [DocumentPicker] Failed to get file size: \(error)")
            }
        }

        // 용량 초과 파일 알림
        if !oversizedFiles.isEmpty {
            let alert = UIAlertController(
                title: "파일 크기 초과",
                message: "다음 파일은 5MB를 초과하여 선택할 수 없습니다:\n\n\(oversizedFiles.joined(separator: "\n"))",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }

        // 유효한 파일이 있으면 업로드
        if !validFiles.isEmpty {
            print("✅ [DocumentPicker] Valid files: \(validFiles.count)")
            uploadFiles(validFiles)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
        print("📄 [DocumentPicker] Cancelled")
    }
}
