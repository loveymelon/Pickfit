//
//  CommunityDetailView.swift
//  Pickfit
//
//  Created by 김진수 on 2025-01-06.
//

import UIKit
import SnapKit
import Then

final class CommunityDetailView: BaseView {

    // MARK: - UI Components

    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = true
        $0.alwaysBounceVertical = true
    }

    private let contentView = UIView()

    // 이미지 페이저
    let imagePageView = UIView().then {
        $0.backgroundColor = .black
    }

    let imageScrollView = UIScrollView().then {
        $0.isPagingEnabled = true
        $0.showsHorizontalScrollIndicator = false
    }

    let pageControl = UIPageControl().then {
        $0.currentPageIndicatorTintColor = .white
        $0.pageIndicatorTintColor = .white.withAlphaComponent(0.3)
        $0.hidesForSinglePage = true
    }

    // 동영상 재생 버튼 오버레이
    let playButtonOverlay = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        $0.isHidden = true  // 기본적으로 숨김 (동영상일 때만 표시)
    }

    let playIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "play.circle.fill")
        $0.tintColor = .white
        $0.contentMode = .scaleAspectFit
    }

    // 상세 정보 컨테이너
    private let detailContainer = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    // 프로필 이미지
    let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 20
        $0.backgroundColor = .systemGray5
    }

    // 작성자 정보 스택 (이름 + 날짜)
    let authorInfoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 2
        $0.alignment = .leading
    }

    let authorNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .semibold)
        $0.textColor = .black
    }

    let createdAtLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .systemGray
    }

    // 제목
    let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .black
        $0.numberOfLines = 0
    }

    // 가게 이름
    let storeNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .systemBlue
    }

    // 내용
    let contentLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .regular)
        $0.textColor = .darkGray
        $0.numberOfLines = 0
    }

    // 좋아요 + 댓글 수
    let infoStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 12
        $0.alignment = .center
    }

    let likeIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "heart")
        $0.tintColor = .systemGray
        $0.contentMode = .scaleAspectFit
    }

    let likeCountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .medium)
        $0.textColor = .darkGray
    }

    let tagsStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .leading
        $0.distribution = .fill
    }

    let tagsScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
    }

    let likeButton = UIButton().then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        $0.tintColor = .systemRed
    }

    // 댓글 영역
    private let commentSectionContainer = UIView().then {
        $0.backgroundColor = .white
    }

    private let commentHeaderView = UIView()

    private let commentIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "bubble.left")
        $0.tintColor = .darkGray
    }

    let commentCountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .darkGray
    }

    private let separatorLine = UIView().then {
        $0.backgroundColor = .systemGray5
    }

    let commentTableView = UITableView().then {
        $0.separatorStyle = .none
        $0.isScrollEnabled = false
        $0.backgroundColor = .white
    }

    let emptyCommentLabel = UILabel().then {
        $0.text = "첫 후기를 남겨보세요!"
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .systemGray
        $0.textAlignment = .center
        $0.isHidden = true
    }

    // 댓글 입력 필드
    let commentInputContainer = UIView().then {
        $0.backgroundColor = .white
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: -2)
        $0.layer.shadowRadius = 4
    }

    let commentTextField = UITextField().then {
        $0.placeholder = "댓글을 입력하세요"
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 17
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        $0.leftViewMode = .always
        $0.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 0))
        $0.rightViewMode = .always
    }

    let submitButton = UIButton().then {
        $0.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        $0.tintColor = .systemGray4
    }

    // MARK: - Configure

    override func configureHierarchy() {
        // ScrollView 추가 (스크롤 가능하도록)
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 이미지 영역
        contentView.addSubview(imagePageView)
        imagePageView.addSubview(imageScrollView)
        imagePageView.addSubview(pageControl)
        imagePageView.addSubview(playButtonOverlay)
        playButtonOverlay.addSubview(playIconImageView)

        // 상세 정보
        contentView.addSubview(detailContainer)

        detailContainer.addSubview(profileImageView)
        detailContainer.addSubview(authorInfoStackView)
        authorInfoStackView.addArrangedSubview(authorNameLabel)
        authorInfoStackView.addArrangedSubview(createdAtLabel)
        detailContainer.addSubview(likeButton)

        detailContainer.addSubview(titleLabel)
        detailContainer.addSubview(storeNameLabel)
        detailContainer.addSubview(contentLabel)

        detailContainer.addSubview(infoStackView)
        infoStackView.addArrangedSubview(likeIconImageView)
        infoStackView.addArrangedSubview(likeCountLabel)

        detailContainer.addSubview(tagsScrollView)
        tagsScrollView.addSubview(tagsStackView)

        // 댓글 영역
        contentView.addSubview(commentSectionContainer)
        commentSectionContainer.addSubview(commentHeaderView)
        commentHeaderView.addSubview(commentIconImageView)
        commentHeaderView.addSubview(commentCountLabel)
        commentSectionContainer.addSubview(separatorLine)
        commentSectionContainer.addSubview(emptyCommentLabel)
        commentSectionContainer.addSubview(commentTableView)

        // 댓글 입력 (ScrollView 밖에 고정)
        addSubview(commentInputContainer)
        commentInputContainer.addSubview(commentTextField)
        commentTextField.addSubview(submitButton)
    }

    override func configureLayout() {
        // ScrollView 레이아웃
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(commentInputContainer.snp.top)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        // 이미지 페이저
        imagePageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * 0.5)
        }

        imageScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-40)
        }

        playButtonOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(80)
        }

        // 상세 정보 컨테이너
        detailContainer.snp.makeConstraints { make in
            make.top.equalTo(imagePageView.snp.bottom).offset(-20)
            make.leading.trailing.equalToSuperview()
        }

        // 프로필 이미지 + 작성자 정보
        profileImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(40)
        }

        authorInfoStackView.snp.makeConstraints { make in
            make.centerY.equalTo(profileImageView)
            make.leading.equalTo(profileImageView.snp.trailing).offset(12)
        }

        likeButton.snp.makeConstraints { make in
            make.centerY.equalTo(profileImageView)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(28)
        }

        // 제목
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // 가게 이름
        storeNameLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // 내용
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(storeNameLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // 좋아요 + 댓글 수
        likeIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }

        infoStackView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
        }

        // 해시태그 스크롤뷰
        tagsScrollView.snp.makeConstraints { make in
            make.top.equalTo(infoStackView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(30)
            make.bottom.equalToSuperview().offset(-20)
        }

        tagsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
            make.height.equalToSuperview()
        }

        // 댓글 영역
        commentSectionContainer.snp.makeConstraints { make in
            make.top.equalTo(detailContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)  // contentView 하단에 맞춤
        }

        commentHeaderView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview().inset(15)
            make.height.equalTo(24)
        }

        commentIconImageView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        commentCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(commentIconImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }

        separatorLine.snp.makeConstraints { make in
            make.top.equalTo(commentHeaderView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        emptyCommentLabel.snp.makeConstraints { make in
            make.top.equalTo(separatorLine.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(150)
        }

        commentTableView.snp.makeConstraints { make in
            make.top.equalTo(separatorLine.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(0) // 동적으로 업데이트
        }

        // 댓글 입력
        commentInputContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()  // safeArea 무시하고 화면 끝까지
            make.height.equalTo(60 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0))
        }

        commentTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(40)
        }

        submitButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalTo(commentTextField)
            make.width.height.equalTo(28)
        }
    }

    override func configureUI() {
        super.configureUI()  // ← 이게 없어서 configureHierarchy()와 configureLayout()이 호출 안 됨!
        backgroundColor = .systemGray6
    }

    // MARK: - Helper Methods

    func updateCommentTableViewHeight(_ height: CGFloat) {
        commentTableView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }

    func showEmptyComment(_ show: Bool) {
        emptyCommentLabel.isHidden = !show
        commentTableView.isHidden = show
    }
}
