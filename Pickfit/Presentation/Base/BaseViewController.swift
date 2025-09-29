//
//  BaseViewController.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import UIKit

class BaseViewController<T: BaseView>: UIViewController {
    
    let mainView = T()
    
    override func loadView() {
        self.view = mainView
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        configureNav()
        bind()
    }
    
//    func configureNav() {
//
//        let navBarAppearance = UINavigationBarAppearance()
//
//        navBarAppearance.backgroundColor = HKColor.background.color
//
//        UINavigationBar.appearance().standardAppearance = navBarAppearance
//        UINavigationBar.appearance().compactAppearance = navBarAppearance
//        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
//
//        navigationController?.navigationBar.tintColor = HKColor.assistant.color
//
//    }
//
//    func setNavigationBarTitleLabel(title: String) {
//        let label = UILabel()
//
//        label.text = title
//        label.textColor = HKColor.text.color
//        label.font = .boldSystemFont(ofSize: 18)
//
//        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
//    }
    
    func bind() {
        
    }

}
