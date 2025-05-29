//
//  Factory.swift
//  ReplaceNotificationCenterWithAdapter
//

import SwiftUI

final class Factory {
    private let network = HttpNetwork()
    private var conversationViewModel: ConversationViewModel?
    
    let keyStore = UserDefaultsKeyStoreService()
    private var chatViewModel: ChatViewModel?
    
    
    private var loginViewModel: LoginViewModel?
}

// Root
extension Factory {
    func createRootView(didLogin: @escaping () -> Void, didGoToConversation: @escaping (String) -> Void) -> some View {
        Text("Loading")
            .onAppear {
                let user: String? = self.keyStore.retrieve(key: .loggedInUserKey)
                if let user = user {
                    didGoToConversation(user)
                } else {
                    didLogin()
                }
            }
    }
    
    func createLogIn(didLogin: @escaping (String) -> Void) -> some View {
        if loginViewModel == nil {
            let secureKeyService = P256SecureKeyService()
            let authentication = PasswordAuthenticationService(secureKey: secureKeyService, keyStore: keyStore)
            loginViewModel = LoginViewModel(service: authentication, didLogin: didLogin)
        }
        guard let loginViewModel = loginViewModel else {
            fatalError("loginViewModel need to be set before use ")
        }
        
        return LogInView(viewModel: loginViewModel)
    }
    func createConversation(sender: String, didTapItem: @escaping (String, String) -> Void, didTapLogOut: @escaping () -> Void) -> some View {
        if conversationViewModel == nil {
            let userService = RemoteUserService(network: network)
            conversationViewModel = ConversationViewModel(sender: sender, service: userService, didTapItem: didTapItem, didTapLogOut: didTapLogOut)
        }
        
        guard let conversationViewModel = conversationViewModel else {
            fatalError("conversationViewModel need to be set before use ")
        }
        
        conversationViewModel.sender = sender
        
        return ConversationView(viewModel: conversationViewModel)
    }
    
    func createChat(sender: String, receiver: String, didTapBack: @escaping () -> Void) -> some View {
        if chatViewModel == nil {
            let encryptService = AESEncryptService()
            let decryptService = AESDecryption()
            let secureKeyService = P256SecureKeyService()
            let messageService = RemoteMessageService(secureKey: secureKeyService, keyStore: keyStore, decryptService: decryptService, network: network)
            let socketService = LocalSocketService(encryptService: encryptService, decryptService: decryptService, keyStore: keyStore)
            chatViewModel = ChatViewModel(sender: sender, receiver: receiver, service: socketService, messageService: messageService, didTapBack: didTapBack)
        }
        
        guard let chatViewModel = chatViewModel else {
            fatalError("chatViewModel need to be set before use ")
        }
        
        chatViewModel.sender = sender
        chatViewModel.receiver = receiver
        
        return ChatView(viewModel: chatViewModel)
    }
}

// Sub
extension Factory {
    
}
