//
//  ViewController.swift
//  RxSwift-QiitaAPI-MVVM
//
//  Created by Ryu on 2022/03/13.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import KRProgressHUD

class ViewController: UIViewController {
    
    private let viewModel:QiitaAPIViewModel
    private let tableView: UITableView
    private var searchBar:UISearchBar!
    private let disposeBag = DisposeBag()
    
    init(viewModel: QiitaAPIViewModel) {
        self.viewModel = viewModel
        self.tableView = UITableView(frame: .zero, style: .plain)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupViews()
        bind()
    }

    private func setupViews() {
        if let navigationBarFrame = navigationController?.navigationBar.frame {
            searchBar = UISearchBar(frame: navigationBarFrame)
            searchBar.placeholder = "テキストを入力"
            searchBar.barStyle = .default
            searchBar.tintColor = .gray
            searchBar.keyboardType = .default
            navigationItem.titleView = searchBar
            navigationItem.titleView?.frame = searchBar.frame
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.top.bottom.left.right.equalTo(view.safeAreaLayoutGuide)
        }
        
    }
    
    private func bind() {
        
        searchBar.rx.searchButtonClicked
            .flatMap { [weak self] () -> Observable<String> in
                return Observable<String>.just(self?.searchBar.text ?? "")
            }
            .bind(to: viewModel.inputs.searchObserver)
            .disposed(by: disposeBag)
        
        searchBar.rx.text.orEmpty
            .flatMap { text -> Observable<Bool> in
                return Observable.just(text.isEmpty)
            }
            .bind(to: viewModel.inputs.textFieldIsEmpty)
            .disposed(by: disposeBag)
        
        viewModel.outputs.result
            .drive(tableView.rx.items(cellIdentifier: "UITableViewCell", cellType: UITableViewCell.self)) { indexPath, apiResponse, cell in
                cell.textLabel?.text = apiResponse.title
            }
            .disposed(by: disposeBag)
        
    }
    
}
