//
//  QiitaAPIViewModel.swift
//  RxSwift-QiitaAPI-MVVM
//
//  Created by Ryu on 2022/03/13.
//
import RxSwift
import RxCocoa
import RxAlamofire
import SwiftyJSON
import KRProgressHUD

protocol QiitaAPIViewModelType: AnyObject {
    var inputs:QiitaAPIViewModelInputs { get }
    var outputs:QiitaAPIViewModelOutputs { get }
}

protocol QiitaAPIViewModelInputs: AnyObject {
    var searchObserver: AnyObserver<String> { get }
    var textFieldIsEmpty: PublishRelay<Bool> { get }
}

protocol QiitaAPIViewModelOutputs: AnyObject {
    var result: Driver<[APIResponse]> { get }
}

final class QiitaAPIViewModel: QiitaAPIViewModelType, QiitaAPIViewModelInputs, QiitaAPIViewModelOutputs {
    var inputs: QiitaAPIViewModelInputs { return self }
    var outputs: QiitaAPIViewModelOutputs { return self }
    
    private let disposeBag = DisposeBag()
    
    //inputs
    private let searchSubject = PublishSubject<String>()
    var textFieldIsEmpty = PublishRelay<Bool>()
    var searchObserver: AnyObserver<String> {
        return searchSubject.asObserver()
    }
    
    //outputs
    private let resultSubject = PublishSubject<[APIResponse]>()
    var result: Driver<[APIResponse]> {
        return resultSubject.asDriver(onErrorJustReturn: [])
    }
    
    init() {
        
        textFieldIsEmpty
            .asObservable()
            .subscribe {[weak self] isEmpty in
                if let isEmpty = isEmpty.element, isEmpty {
                    self?.resultSubject.onNext([])
                    self?.searchSubject.onNext("")
                }
            }
            .disposed(by: disposeBag)
        
        searchSubject
            .asObservable()
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .do(onNext: {text in
                if !text.isEmpty {
                    KRProgressHUD.show(withMessage: "検索中")
                }
            })
            .flatMapLatest { text -> Observable<[APIResponse]> in
                if !text.isEmpty {
                    return API.getTitles(searchText: text, token: "YOUR_API_TOKEN")
                }
                else{
                    return Observable.just([])
                }
            }
            .subscribe {[weak self] res in
                if let element = res.element {
                    KRProgressHUD.dismiss()
                    self?.resultSubject.onNext(element)
                }
            }
            .disposed(by: disposeBag)
        
    }
    
}

class API {
    
    static let apiURL = "https://qiita.com/api/v2/items?page=1&per_page=100&query=body:"
    static func getTitles(searchText: String, token: String) -> Observable<[APIResponse]> {
        
        return RxAlamofire
            .json(.get, apiURL + searchText, headers: ["Authorization" : "Bearer " + token])
            .flatMap { response -> Observable<[APIResponse]> in
                let json = JSON(response)
                var responses = [APIResponse]()
                
                for (_, partial) in json {
                    
                    if let title = partial["title"].string,
                       let createdAt = partial["created_at"].string,
                       let userId = partial["user"]["id"].string,
                       let userName = partial["user"]["name"].string,
                       let likesCount = partial["likes_count"].int
                    {
                        
                        responses.append(
                            APIResponse(
                                title: title,
                                createdAt: createdAt,
                                userId: userId,
                                userName: userName,
                                likesCount: likesCount
                            )
                        )
                        
                    }
                    
                }
                
                return Observable<[APIResponse]>.just(responses)
            }
    }
    
}
