//
//  SignUpViewModel.swift
//  iTamin
//
//  Created by Tabber on 2022/09/24.
//

import SwiftUI
import Combine
import CombineCocoa

class SignUpViewModel: ObservableObject {
    @Published private var nickNameText: String = ""
    @Published var allSelect: Bool = false
    @Published var oneButtonSelect: Bool = false
    @Published var twoButtonSelect: Bool = false
    var descriptionArray: [String] = []
    @Published var currentInex: Int = 0
    
    @Published var emailText: String = ""
    @Published var passwordText: String = ""
    @Published var passwordCheckText: String = ""
    
    var emailCheck = PassthroughSubject<Bool, Never>()
    
    var networkManager = NetworkManager()
    var cancelBag = CancelBag()
    func checkEmail(text: String) {
        networkManager.emailCheckToServer(string: text)
            .sink(receiveCompletion: { _ in }, receiveValue: { data in
                self.emailCheck.send(data.data)
            })
            .cancel(with: cancelBag)
        
    }
    
    var userDataIsValid: AnyPublisher<Bool, Never> {
        return Publishers.CombineLatest3($emailText, $passwordText, $passwordCheckText)
            .map { email, password, passwordCheck in
                return self.isValidEmail(testStr: email) && (password.count > 8 && password.count < 30) && password == passwordCheck
            }
            .eraseToAnyPublisher()
    }
    
    var isValid: AnyPublisher<Bool, Never> {
        return $nickNameText
            .map { text in
                return text.count > 0 && text.count <= 9
            }
            .eraseToAnyPublisher()
    }
    
    func typingText(_ text: String) {
        nickNameText = text
    }
    
    func showUserName() -> String {
        return nickNameText
    }

    var isAllSelect: AnyPublisher<Bool, Never> {
        return Publishers.CombineLatest($oneButtonSelect, $twoButtonSelect)
            .map { one, two in
                return one && two
            }
            .eraseToAnyPublisher()
    }
    
    func validpassword(mypassword : String) -> Bool {
        let passwordreg =  ("(?=.*[A-Za-z])(?=.*[0-9]).{8,30}")
        let passwordtesting = NSPredicate(format: "SELF MATCHES %@", passwordreg)
        return passwordtesting.evaluate(with: mypassword)
    }
    
    var passwordCheckPublisher: AnyPublisher<Bool, Never> {
        return $passwordText
            .map { text in
                return self.validpassword(mypassword: text)
            }
            .eraseToAnyPublisher()
    }
    
    var passwordBetweenCheck: AnyPublisher<Bool, Never> {
        return $passwordCheckText
            .map { text in
                return self.passwordText == text
            }
            .eraseToAnyPublisher()
    }
    
    func setDescription() {
        descriptionArray = ["안녕하세요, \(nickNameText)님!\n매일 챙겨먹는 마음 비타민\n마이타민입니다!",
                            "하루의 끝에서\n오늘의 나를 진단해보고\n칭찬 처방을 내려보세요",
                            "적어도 한달에 한번은\n오로지 자신의 행복을 위한\n하루가 되도록 도울게요.",
                            "하루를 마무리하는 시간은\n 언제쯤 인가요?"]
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}
