//
//  ChatListView.swift
//  Pickfit
//
//  Created by Claude on 10/11/25.
//

import UIKit
import SnapKit
import Then

final class ChatListView: BaseView {

    private let headerView = UIView().then {
        $0.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
    }

    private let titleLabel = UILabel().then {
        $0.text = "채팅"
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .left
    }

    private let tabContainerView = UIView().then {
        $0.backgroundColor = .clear
    }

    let allChatsButton = UIButton().then {
        $0.setTitle("전체", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
        $0.layer.cornerRadius = 16
        $0.tag = 0
    }

    let unreadChatsButton = UIButton().then {
        $0.setTitle("안읽음", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        $0.setTitleColor(.white.withAlphaComponent(0.6), for: .normal)
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 16
        $0.tag = 1
    }

    private let contentContainerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 24
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    private let recentChatsLabel = UILabel().then {
        $0.text = "Recent Chats"
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .darkGray
    }

    private let searchButton = UIButton().then {
        $0.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        $0.tintColor = .darkGray
    }

    let tableView = UITableView().then {
        $0.backgroundColor = .white
        $0.separatorStyle = .none
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 88
        $0.register(ChatListCell.self, forCellReuseIdentifier: ChatListCell.identifier)
        $0.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        $0.showsVerticalScrollIndicator = false
    }

    let emptyLabel = UILabel().then {
        $0.text = "채팅 내역이 없습니다"
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .systemGray
        $0.textAlignment = .center
        $0.isHidden = true
    }

    let refreshControl = UIRefreshControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureHierarchy() {
        addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(tabContainerView)
        tabContainerView.addSubview(allChatsButton)
        tabContainerView.addSubview(unreadChatsButton)

        addSubview(contentContainerView)
        contentContainerView.addSubview(recentChatsLabel)
        contentContainerView.addSubview(searchButton)
        contentContainerView.addSubview(tableView)
        contentContainerView.addSubview(emptyLabel)

        tableView.refreshControl = refreshControl
    }

    override func configureLayout() {
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(180)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(12)
            $0.leading.equalToSuperview().offset(20)
        }

        tabContainerView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        allChatsButton.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(70)
            $0.height.equalTo(32)
        }

        unreadChatsButton.snp.makeConstraints {
            $0.leading.equalTo(allChatsButton.snp.trailing).offset(12)
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(70)
            $0.height.equalTo(32)
        }

        contentContainerView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        recentChatsLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        searchButton.snp.makeConstraints {
            $0.centerY.equalTo(recentChatsLabel)
            $0.trailing.equalToSuperview().offset(-20)
            $0.width.height.equalTo(24)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(recentChatsLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    override func configureUI() {
        super.configureUI()
        backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
    }

    func showEmpty(_ isEmpty: Bool) {
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    /// 필터 탭 선택 상태 업데이트
    func updateFilterSelection(isAllSelected: Bool) {
        if isAllSelected {
            // 전체 탭 선택
            allChatsButton.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
            allChatsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            allChatsButton.setTitleColor(.white, for: .normal)

            unreadChatsButton.backgroundColor = .clear
            unreadChatsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            unreadChatsButton.setTitleColor(.white.withAlphaComponent(0.6), for: .normal)
        } else {
            // 안읽음 탭 선택
            allChatsButton.backgroundColor = .clear
            allChatsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            allChatsButton.setTitleColor(.white.withAlphaComponent(0.6), for: .normal)

            unreadChatsButton.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
            unreadChatsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            unreadChatsButton.setTitleColor(.white, for: .normal)
        }
    }
}
