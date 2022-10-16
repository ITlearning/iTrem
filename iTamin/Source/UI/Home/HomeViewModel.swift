//
//  HomeViewModel.swift
//  iTamin
//
//  Created by Tabber on 2022/09/27.
//

import UIKit
import SwiftUI
import SwiftKeychainWrapper
import Combine

extension HomeViewController {
    class ViewModel: ObservableObject {
        @Published var userData: WelComeModel?
        
        var buttonClick = PassthroughSubject<Int, Never>()
        var subTextPublisher = CurrentValueSubject<String, Never>("")
        var getLatestData = PassthroughSubject<Bool, Never>()
        var latestData = CurrentValueSubject<LatestMyTaminModel?, Never>(nil)
        @Published var careData: CareModel? = nil
        @Published var reportData: ReportModel? = nil
        @Published var dataIsReady: Bool = false
        var loadingMainScreen = PassthroughSubject<Bool, Never>()
        var viewIsReady = PassthroughSubject<Bool, Never>()
        var networkManager = NetworkManager()
        var cancelBag = CancelBag()
        
        var mainCellItems = CurrentValueSubject<[MainCollectionModel], Never>(
            [MainCollectionModel(isDone: false, cellDescription: "숨 고르기", image: "MyTamin01"),
            MainCollectionModel(isDone: false, cellDescription: "감각 깨우기", image: "MyTamin02"),
            MainCollectionModel(isDone: false, cellDescription: "하루 진단하기", image: "MyTamin03"),
            MainCollectionModel(isDone: false, cellDescription: "칭찬 처방하기", image: "MyTamin04")]
        )
        
        init() {
            loadWelComeComment()
        }
        
        func checkStatus() {
            loadingMainScreen.send(false)
            
            networkManager.checkMyTaminStatus()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { result in
                    self.mainCellItems.send([
                        MainCollectionModel(isDone: result.data.breathIsDone, cellDescription: "숨 고르기", image: "MyTamin01"),
                        MainCollectionModel(isDone: result.data.senseIsDone, cellDescription: "감각 깨우기", image: "MyTamin02"),
                        MainCollectionModel(isDone: result.data.reportIsDone, cellDescription: "하루 진단하기", image: "MyTamin03"),
                        MainCollectionModel(isDone: result.data.careIsDone, cellDescription: "칭찬 처방하기", image: "MyTamin04")
                    ])
                    
                    UserDefaults.standard.set(result.data.breathIsDone, forKey: .breathIsDone)
                    UserDefaults.standard.set(result.data.senseIsDone, forKey: .senseIsDone)
                    UserDefaults.standard.set(result.data.reportIsDone, forKey: .reportIsDone)
                    UserDefaults.standard.set(result.data.careIsDone, forKey: .careIsDone)
                    
                    if !UserDefaults.standard.bool(forKey: .reportIsDone) {
                        UserDefaults.standard.set(1, forKey: .mindSelectIndex)
                    }
                    
                    if result.data.reportIsDone && result.data.careIsDone {
                        self.getLatestData.send(true)
                    } else {
                        self.getLatestData.send(false)
                    }
                    
                    self.loadingMainScreen.send(true)
                })
                .cancel(with: cancelBag)
        }
        
        func loadWelComeComment() {
            
            loadingMainScreen.send(false)
            
            networkManager.welcomeToServer()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                    guard let self = self else {return}
                    self.userData = result.data
                    
                    self.loadingMainScreen.send(true)
                    
                })
                .cancel(with: cancelBag)
        }
        
        func loadDailyReport() {
            
            withAnimation {
                dataIsReady = false
            }
            
            self.reportData = nil
            
            networkManager.loadDailyReportData()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { value in
                    let data = value.data
                    self.reportData = data
                    UserDefaults.standard.set(value.data.reportId, forKey: .reportId)
                    withAnimation {
                        self.dataIsReady = true
                    }
                })
                .cancel(with: cancelBag)
        }
        
        
        func loadCareReport() {
            withAnimation {
                dataIsReady = false
            }
            self.careData = nil
            
            networkManager.loadCareReportData()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { value in
                    self.careData = value.data
                    UserDefaults.standard.set(value.data.careId, forKey: .careId)
                    withAnimation {
                        self.dataIsReady = true
                    }
                })
                .cancel(with: cancelBag)
        }
        
        func loadLatestData() {
            
            withAnimation {
                dataIsReady = false
            }
            
            self.careData = nil
            self.reportData = nil
            
            networkManager.getLatestMyTaminData()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in
                }, receiveValue: { result in
                    
                    self.careData = result.data.care
                    self.reportData = result.data.report
                    
                    UserDefaults.standard.set(result.data.report.reportId, forKey: .reportId)
                    UserDefaults.standard.set(result.data.care.careId, forKey: .careId)
                    
                    withAnimation {
                        self.dataIsReady = true
                    }
                })
                .cancel(with: cancelBag)
        }
    }
}
