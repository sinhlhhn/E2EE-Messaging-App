//
//  SwiftUIView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 22/5/25.
//

import SwiftUI

struct LogInView: View {
    @State private var email: String = "A"
    @State private var password: String = "A"
    
    @State var viewModel: LoginViewModel
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            TextField("Password", text: $password)
            
            Button("Login") {
                viewModel.logIn(email: email, password: password)
            }
            
            Button("Register") {
                viewModel.register(email: email, password: password)
            }
        }
        .toolbar(.hidden)
    }
}

import Combine

@Observable
class LoginViewModel {
    let service: any AuthenticationUseCase<PasswordAuthentication>
    private let didLogin: (User) -> Void
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(service: any AuthenticationUseCase<PasswordAuthentication>, didLogin: @escaping (User) -> Void) {
        self.service = service
        self.didLogin = didLogin
    }
    
    func logIn(email: String, password: String) {
        service.login(data: .init(email: email, password: password))
            .sink { completion in
                debugPrint("logIn completed \(completion)")
            } receiveValue: { [weak self] user in
                self?.didLogin(user)
            }
            .store(in: &cancellables)

    }
    
    func register(email: String, password: String) {
        service.register(data: .init(email: email, password: password))
            .sink { completion in
                debugPrint("register completed \(completion)")
            } receiveValue: { [weak self] user in
                self?.didLogin(user)
            }
            .store(in: &cancellables)
    }
}

#Preview {
    LogInView(viewModel: LoginViewModel(service: NullAuthenticationService<PasswordAuthentication>(), didLogin: { _ in }))
}
