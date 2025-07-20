//
//  ConversationView.swift
//  MessagingApp
//
//  Created by Sam on 22/5/25.
//

import SwiftUI

struct ConversationView: View {
    @Bindable var viewModel: ConversationViewModel
    
    init(viewModel: ConversationViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            Text("\(viewModel.sender)")
            List(viewModel.users) { user in
                HStack {
                    Text(user.username)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.select(user: user)
                }
            }
            .refreshable {
                viewModel.fetchUsers()
            }
        }
        .onAppear {
            viewModel.fetchUsers()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.logout()
                } label: {
                    Text("Log Out")
                        .foregroundStyle(Color.red)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationTitle("Conversation")
    }
}



import Combine
@Observable
class ConversationViewModel {
    var users: [User] = []
    var sender: User
    
    private let service: UserUseCase
    private let logOutUseCase: LogOutUseCase
    private var cancellables: Set<AnyCancellable> = []
    private let didTapItem: (User, String) -> Void
    private let didTapLogOut: () -> Void
    
    init(sender: User, logOutUseCase: LogOutUseCase, service: UserUseCase, didTapItem: @escaping (User, String) -> Void, didTapLogOut: @escaping () -> Void) {
        self.logOutUseCase = logOutUseCase
        self.sender = sender
        self.service = service
        self.didTapItem = didTapItem
        self.didTapLogOut = didTapLogOut
    }
    
    func fetchUsers() {
        service.fetchUsers()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    //TODO: -show error state
                    debugPrint("❌ fetchUsers failed")
                case .finished: break
                }
            } receiveValue: { [weak self] users in
                self?.users = users
            }
            .store(in: &cancellables)

    }
    
    func select(user: User) {
        didTapItem(sender, user.username)
    }
    
    func logout() {
        logOutUseCase.logOut(userName: sender.username)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    //TODO: -show error state
                    debugPrint("❌ logout failed")
                case .finished: break
                }
            } receiveValue: { [weak self] _ in
                self?.didTapLogOut()
            }
            .store(in: &cancellables)
    }
}

#Preview {
    ConversationView(viewModel: ConversationViewModel(sender: User(id: 0, username: ""), logOutUseCase: NullLogOutUseCase(), service: NullUserService(), didTapItem: { _, _ in }, didTapLogOut: {}))
}
