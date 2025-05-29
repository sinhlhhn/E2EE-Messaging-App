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
        }
        .onAppear {
            viewModel.fetchUsers()
        }
        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button {
//                    viewModel.logout()
//                } label: {
//                    Text("Log Out")
//                        .foregroundStyle(Color.red)
//                }
//            }
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
    var sender: String
    
    private let service: UserUseCase
    private var cancellables: Set<AnyCancellable> = []
    private let didTapItem: (String, String) -> Void
    private let didTapLogOut: () -> Void
    
    init(sender: String, service: UserUseCase, didTapItem: @escaping (String, String) -> Void, didTapLogOut: @escaping () -> Void) {
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
        didTapLogOut()
    }
}

#Preview {
    ConversationView(viewModel: ConversationViewModel(sender: "", service: NullUserService(), didTapItem: { _, _ in }, didTapLogOut: {}))
}
