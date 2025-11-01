//
//  CommunityDetailViewController.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-06.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import AVKit
import Kingfisher

final class CommunityDetailViewController: BaseViewController<CommunityDetailView> {

    var disposeBag = DisposeBag()
    private let reactor: CommunityDetailReactor

    private var imageViews: [UIView] = []
    private var currentVideoURL: String?  // 현재 표시 중인 동영상 URL

    // MARK: - Initialization

    init(postId: String) {
        self.reactor = CommunityDetailReactor(postId: postId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎬 [CommunityDetailVC] viewDidLoad 시작")

        setupNavigationBar()
        setupTableView()
        setupRefreshControl()
        setupProfileTapGesture()  // 프로필 탭 제스처 설정
        hideCartButton()  // 장바구니 버튼 숨김

        print("🚀 [CommunityDetailVC] viewDidLoad Action 발송")
        reactor.action.onNext(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("👁️ [CommunityDetailVC] viewWillAppear")

        // TabBar 숨김
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // TabBar 다시 표시
        tabBarController?.tabBar.isHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("👁️ [CommunityDetailVC] viewDidAppear")
        print("   📐 view.frame: \(view.frame)")
        print("   📐 mainView.frame: \(mainView.frame)")
//        print("   📐 spotNameLabel.frame: \(mainView.spotNameLabel.frame)")
//        print("   🎨 spotNameLabel visible: \(!mainView.spotNameLabel.isHidden)")
//        print("   🎨 spotNameLabel alpha: \(mainView.spotNameLabel.alpha)")
    }

    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        mainView.scrollView.refreshControl = refreshControl
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)

        // 뒤로 가기 버튼
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton

        // 카테고리 타이틀
        let titleLabel = UILabel().then {
            $0.text = "카페"  // TODO: 동적으로 변경
            $0.font = .systemFont(ofSize: 16, weight: .semibold)
            $0.textColor = .black
        }
        navigationItem.titleView = titleLabel

        // 더보기 버튼
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(moreButtonTapped)
        )
        moreButton.tintColor = .black
        navigationItem.rightBarButtonItem = moreButton
    }

    private func setupTableView() {
        mainView.commentTableView.delegate = self
        mainView.commentTableView.dataSource = self
        mainView.commentTableView.register(CommentCell.self, forCellReuseIdentifier: CommentCell.identifier)
    }

    private func setupProfileTapGesture() {
        // 프로필 이미지 + 작성자 정보 영역을 담을 컨테이너 뷰 생성
        let profileContainerView = UIView()
        profileContainerView.backgroundColor = .clear

        // mainView의 scrollView에서 프로필 영역 찾기
        // profileImageView와 authorInfoStackView를 감싸는 영역
        if let scrollView = mainView.scrollView.subviews.first as? UIView {
            profileContainerView.frame = CGRect(x: 20, y: 16, width: 200, height: 44)
            scrollView.addSubview(profileContainerView)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        mainView.profileImageView.addGestureRecognizer(tapGesture)
        mainView.profileImageView.isUserInteractionEnabled = true
    }

    @objc private func profileTapped() {
        print("👆 [CommunityDetail] 프로필 탭됨")
        reactor.action.onNext(.profileTapped)
    }

    // MARK: - Bind

    override func bind() {
        super.bind()

        bindActions()
        bindState()
    }

    private func bindActions() {
        // 스크롤뷰 새로고침
        mainView.scrollView.refreshControl?.rx.controlEvent(.valueChanged)
            .map { CommunityDetailReactor.Action.refresh }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 좋아요 버튼
        mainView.likeButton.rx.tap
            .map { CommunityDetailReactor.Action.tappedArchiveButton }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 댓글 텍스트 변경
        mainView.commentTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .map { CommunityDetailReactor.Action.updateCommentText($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 댓글 전송 버튼
        mainView.submitButton.rx.tap
            .map { CommunityDetailReactor.Action.tappedSubmitComment }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 키보드 숨기기
        let tapGesture = UITapGestureRecognizer()
        view.addGestureRecognizer(tapGesture)  // scrollView 대신 view 사용
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
    }

    private func bindState() {
        // Spot Detail 데이터 바인딩
        reactor.state.map { $0.spotDetail }
            .compactMap { $0 }
            .distinctUntilChanged({ $0.postId == $1.postId })
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] detail in
                self?.updateSpotDetail(detail)
            })
            .disposed(by: disposeBag)

        // 댓글 리스트 바인딩
        reactor.state.map { $0.comments }
            .distinctUntilChanged { $0.count == $1.count }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] comments in
                self?.updateComments(comments)
            })
            .disposed(by: disposeBag)

        // 좋아요 상태
        reactor.state.map { $0.isArchived }
            .distinctUntilChanged()
            .bind(to: mainView.likeButton.rx.isSelected)
            .disposed(by: disposeBag)

        // 댓글 입력 필드 초기화
        reactor.state.map { $0.commentText }
            .distinctUntilChanged()
            .bind(to: mainView.commentTextField.rx.text)
            .disposed(by: disposeBag)

        // 전송 버튼 활성화 상태
        reactor.state.map { !$0.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isEnabled in
                self?.mainView.submitButton.tintColor = isEnabled ? .systemBlue : .systemGray4
                self?.mainView.submitButton.isEnabled = isEnabled
            })
            .disposed(by: disposeBag)

        // 로딩 상태
        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isLoading in
                if !isLoading {
                    self?.mainView.scrollView.refreshControl?.endRefreshing()
                }
            })
            .disposed(by: disposeBag)

        // 프로필 바텀시트 표시
        reactor.state.map { $0.shouldShowProfileBottomSheet }
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.showProfileBottomSheet()
            })
            .disposed(by: disposeBag)

        // 채팅방 생성 완료 → ChatViewController 이동
        reactor.state.map { $0.createdChatRoomInfo }
            .compactMap { $0 }
            .distinctUntilChanged { $0.roomId == $1.roomId }
            .subscribe(onNext: { [weak self] roomInfo in
                print("✅ [CommunityDetailVC] 채팅방 이동 - roomId: \(roomInfo.roomId)")
                let chatVC = ChatViewController(roomInfo: (
                    roomId: roomInfo.roomId,
                    nickname: roomInfo.nickname,
                    profileImageUrl: roomInfo.profileImage
                ))
                self?.navigationController?.pushViewController(chatVC, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Update UI

    private func updateSpotDetail(_ detail: SpotDetailEntity) {
        // 프로필 이미지
        if let profileImageUrl = detail.authorProfileImage, !profileImageUrl.isEmpty {
            let fullURL: String
            if profileImageUrl.hasPrefix("http://") || profileImageUrl.hasPrefix("https://") {
                fullURL = profileImageUrl
            } else {
                fullURL = "http://pickup.sesac.kr:31668/v1" + profileImageUrl
            }

            Task {
                let accessToken = await KeychainAuthStorage.shared.readAccess()

                let modifier = AnyModifier { request in
                    var modifiedRequest = request
                    modifiedRequest.setValue(APIKey.sesacKey, forHTTPHeaderField: "SeSACKey")
                    if let token = accessToken {
                        modifiedRequest.setValue(token, forHTTPHeaderField: "Authorization")
                    }
                    return modifiedRequest
                }

                await MainActor.run {
                    self.mainView.profileImageView.kf.setImage(
                        with: URL(string: fullURL),
                        placeholder: UIImage(systemName: "person.circle.fill"),
                        options: [
                            .requestModifier(modifier),
                            .transition(.fade(0.2)),
                            .cacheOriginalImage
                        ]
                    )
                }
            }
        } else {
            mainView.profileImageView.image = UIImage(systemName: "person.circle.fill")
            mainView.profileImageView.tintColor = .systemGray3
        }

        // 작성자 정보
        mainView.authorNameLabel.text = detail.authorName
        mainView.createdAtLabel.text = detail.createdAt

        // 제목
        mainView.titleLabel.text = detail.title

        // 가게 이름
        if let storeName = detail.storeName {
            mainView.storeNameLabel.text = "📍 \(storeName)"
            mainView.storeNameLabel.isHidden = false
        } else {
            mainView.storeNameLabel.isHidden = true
        }

        // 내용
        mainView.contentLabel.text = detail.content

        // 좋아요 수
        mainView.likeCountLabel.text = "\(detail.likeCount)"

        // 태그
        mainView.tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        detail.tags.forEach { tag in
            let displayTag = tag.hasPrefix("#") ? tag : "#\(tag)"
            let tagLabel = UILabel().then {
                $0.text = displayTag
                $0.font = .systemFont(ofSize: 12, weight: .regular)
                $0.textColor = .systemBlue
                $0.backgroundColor = .systemBlue.withAlphaComponent(0.1)
                $0.textAlignment = .center
                $0.setContentHuggingPriority(.required, for: .horizontal)
                $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            }

            let containerView = UIView()
            containerView.addSubview(tagLabel)
            tagLabel.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(4)
                make.leading.trailing.equalToSuperview().inset(12)
            }

            mainView.tagsStackView.addArrangedSubview(containerView)
        }

        mainView.tagsScrollView.layoutIfNeeded()

        // 네비게이션 타이틀
        if let titleLabel = navigationItem.titleView as? UILabel {
            titleLabel.text = detail.categoryId
        }

        // 이미지 페이저 설정
        DispatchQueue.main.async { [weak self] in
            self?.setupImagePager(with: detail.images)
        }
    }

    private func setupImagePager(with imageUrls: [String]) {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()

        let containerView = mainView.imagePageView

        if let firstUrl = imageUrls.first {
            let imageLoadView = ImageLoadView(
                cornerRadius: 0,
                contentMode: .scaleAspectFill,
                cachingStrategy: .diskAndMemory
            )

            imageLoadView.backgroundColor = .systemGray5

            let isVideo = isVideoFile(firstUrl)

            if isVideo {
                imageLoadView.loadVideoThumbnail(from: firstUrl)
            } else {
                imageLoadView.loadImage(from: firstUrl)
            }

            containerView.insertSubview(imageLoadView, at: 0)
            imageViews.append(imageLoadView)

            imageLoadView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            mainView.playButtonOverlay.isHidden = !isVideo

            if isVideo {
                currentVideoURL = firstUrl
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playButtonTapped))
                mainView.playButtonOverlay.addGestureRecognizer(tapGesture)
                mainView.playButtonOverlay.isUserInteractionEnabled = true
            }

            imageLoadView.layoutIfNeeded()
        }

        mainView.pageControl.isHidden = true
    }

    /// 동영상 파일인지 확인
    private func isVideoFile(_ urlString: String) -> Bool {
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "webm", "gif"]
        let lowercased = urlString.lowercased()
        return videoExtensions.contains { lowercased.hasSuffix(".\($0)") }
    }

    private func updateComments(_ comments: [CommentEntity]) {
        mainView.showEmptyComment(comments.isEmpty)
        mainView.commentCountLabel.text = "\(comments.count)"
        mainView.commentTableView.reloadData()

        // 테이블뷰 높이 업데이트
        mainView.commentTableView.layoutIfNeeded()
        let contentHeight = mainView.commentTableView.contentSize.height
        mainView.updateCommentTableViewHeight(contentHeight)
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func playButtonTapped() {
        guard let videoURLString = currentVideoURL else {
            print("❌ [Play] 동영상 URL이 없습니다")
            return
        }

        print("🎬 [Play] 재생 버튼 탭됨")
        print("   - videoURL: \(videoURLString)")

        // 로딩 인디케이터 표시 (옵션)
        let loadingAlert = UIAlertController(title: nil, message: "동영상을 불러오는 중...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor).isActive = true
        loadingIndicator.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20).isActive = true
        present(loadingAlert, animated: true)

        // 동영상 다운로드 후 재생
        Task {
            do {
                let localURL = try await downloadVideo(from: videoURLString)

                await MainActor.run {
                    // 로딩 인디케이터 숨기기
                    loadingAlert.dismiss(animated: true) {
                        // 로컬 파일로 재생
                        self.playVideo(from: localURL)
                    }
                }
            } catch {
                print("❌ [Play] 동영상 다운로드 실패: \(error.localizedDescription)")
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        let alert = UIAlertController(
                            title: "재생 오류",
                            message: "동영상을 불러올 수 없습니다.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "확인", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }

    private func downloadVideo(from urlString: String) async throws -> URL {
        print("   📥 [Download] 동영상 다운로드 시작")

        // 상대 경로를 절대 경로로 변환
        let fullURLString: String
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            fullURLString = urlString
        } else {
            let baseURL = "http://pickup.sesac.kr:31668/v1"
            fullURLString = baseURL + urlString
        }

        guard let videoURL = URL(string: fullURLString) else {
            throw NSError(domain: "CommunityDetail", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        print("   🌐 Full URL: \(fullURLString)")

        // URLRequest 생성 (인증 헤더 추가)
        var request = URLRequest(url: videoURL)
        request.setValue(APIKey.sesacKey, forHTTPHeaderField: "SeSACKey")

        let accessToken = await KeychainAuthStorage.shared.readAccess()
        if let token = accessToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
            print("   🔐 Authorization 헤더 추가 완료")
        }

        // 다운로드
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "CommunityDetail", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        print("   📊 HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "CommunityDetail", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
        }

        // 임시 파일로 저장
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = (urlString as NSString).lastPathComponent
        let fileURL = tempDir.appendingPathComponent(fileName)

        try data.write(to: fileURL)
        print("   ✅ 동영상 저장 완료: \(fileURL.path)")
        print("   📦 파일 크기: \(data.count / 1024 / 1024)MB")

        return fileURL
    }

    private func playVideo(from localURL: URL) {
        print("   ▶️ [Play] 로컬 파일 재생 시작")
        print("   📂 파일 경로: \(localURL.path)")

        // AVPlayer 생성
        let playerItem = AVPlayerItem(url: localURL)
        let player = AVPlayer(playerItem: playerItem)

        // 에러 관찰
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            print("❌ [Player] Failed to play to end time")
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                print("   Error: \(error.localizedDescription)")
            }
        }

        // Status 관찰
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)

        // AVPlayerViewController 생성
        let playerVC = AVPlayerViewController()
        playerVC.player = player

        // 전체화면으로 표시
        present(playerVC, animated: true) {
            player.play()
            print("   ▶️ 재생 시작")
        }
    }


    @objc private func moreButtonTapped() {
        let isAuthor = reactor.currentState.isAuthor

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if isAuthor {
            // 작성자
            alertController.addAction(UIAlertAction(title: "게시글 수정하기", style: .default) { [weak self] _ in
                self?.reactor.action.onNext(.tappedEditPost)
            })
            alertController.addAction(UIAlertAction(title: "게시글 삭제하기", style: .destructive) { [weak self] _ in
                self?.showDeleteConfirmation()
            })
        } else {
            // 다른 사용자
            alertController.addAction(UIAlertAction(title: "게시글 신고하기", style: .default) { [weak self] _ in
                self?.reactor.action.onNext(.tappedReportPost)
            })
            alertController.addAction(UIAlertAction(title: "사용자 신고하기", style: .default) { [weak self] _ in
                self?.reactor.action.onNext(.reportUser)
            })
        }

        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alertController, animated: true)
    }

    private func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "게시물을 삭제하시겠습니까?",
            message: "한 번 삭제된 게시물은 복원할 수 없습니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.reactor.action.onNext(.tappedDeletePost)
            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }

    private func showProfileBottomSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "채팅보내기", style: .default) { [weak self] _ in
            print("💬 [CommunityDetail] 채팅보내기 선택됨")
            self?.reactor.action.onNext(.startChat)
        })

        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alertController, animated: true)
    }

    // MARK: - KVO Observer

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let playerItem = object as? AVPlayerItem {
            print("   📊 [Player] Status changed: \(playerItem.status.rawValue)")
            switch playerItem.status {
            case .readyToPlay:
                print("   ✅ [Player] Ready to play")
                // 자동 재생은 이미 present 완료 후 시작됨
            case .failed:
                print("   ❌ [Player] Failed")
                if let error = playerItem.error {
                    print("      Error: \(error.localizedDescription)")
                    print("      Full error: \(error)")
                }
            case .unknown:
                print("   ❓ [Player] Unknown status")
            @unknown default:
                print("   ⚠️ [Player] Unknown status: \(playerItem.status.rawValue)")
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension CommunityDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reactor.currentState.comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.identifier, for: indexPath) as! CommentCell
        let comment = reactor.currentState.comments[indexPath.row]

        cell.configure(with: comment)

        // 삭제/신고 버튼 클릭
        cell.actionButtonTapped = { [weak self] in
            self?.showCommentActionSheet(at: indexPath.row, isAuthor: comment.isAuthor)
        }

        return cell
    }

    private func showCommentActionSheet(at index: Int, isAuthor: Bool) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if isAuthor {
            alertController.addAction(UIAlertAction(title: "삭제하기", style: .destructive) { [weak self] _ in
                self?.reactor.action.onNext(.deleteComment(index))
            })
        } else {
            alertController.addAction(UIAlertAction(title: "신고하기", style: .destructive) { [weak self] _ in
                self?.reactor.action.onNext(.reportComment(index))
            })
        }

        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alertController, animated: true)
    }
}

// MARK: - CommentCell

final class CommentCell: UITableViewCell {
    var actionButtonTapped: (() -> Void)?

    private let nicknameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .black
    }

    private let actionButton = UIButton().then {
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
    }

    private let commentLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .darkGray
        $0.numberOfLines = 0
    }

    private let dateLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .systemGray
    }

    private let separatorView = UIView().then {
        $0.backgroundColor = .systemGray5
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none

        [nicknameLabel, actionButton, commentLabel, dateLabel, separatorView].forEach {
            contentView.addSubview($0)
        }

        nicknameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(15)
        }

        actionButton.snp.makeConstraints { make in
            make.centerY.equalTo(nicknameLabel)
            make.trailing.equalToSuperview().offset(-15)
        }

        commentLabel.snp.makeConstraints { make in
            make.top.equalTo(nicknameLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(15)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(commentLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-12)
        }

        separatorView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        actionButton.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
    }

    func configure(with comment: CommentEntity) {
        nicknameLabel.text = comment.memberName
        nicknameLabel.textColor = comment.isAuthor ? .systemBlue : .black
        commentLabel.text = comment.reviewText
        dateLabel.text = comment.reviewDate

        actionButton.setTitle(comment.isAuthor ? "삭제하기" : "신고하기", for: .normal)
        actionButton.setTitleColor(comment.isAuthor ? .systemGray : .systemRed, for: .normal)
    }

    @objc private func actionButtonTapped(_ sender: UIButton) {
        actionButtonTapped?()
    }
}
