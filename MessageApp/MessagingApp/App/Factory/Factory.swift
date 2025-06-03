//
//  Factory.swift
//  ReplaceNotificationCenterWithAdapter
//

import SwiftUI

final class Factory {
    private var network: AuthenticatedNetwork?
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
            let authenticatedNetwork = HttpAuthenticationNetwork { [weak self] accessToken in
                self?.createAuthenticatedNetwork(accessToken: accessToken)
            }
            let secureKeyService = P256SecureKeyService()
            let restoreKey = RemoteRestoreKeyModule()
            let authentication = PasswordAuthenticationService(authenticatedNetwork: authenticatedNetwork, network: getAuthenticatedNetwork(), secureKey: secureKeyService, keyStore: keyStore, restoreKey: restoreKey)
            loginViewModel = LoginViewModel(service: authentication, didLogin: didLogin)
        }
        guard let loginViewModel = loginViewModel else {
            fatalError("loginViewModel need to be set before use ")
        }
        
        return LogInView(viewModel: loginViewModel)
    }
    
    private func createAuthenticatedNetwork(accessToken: String) {
        network = AuthenticatedNetwork(accessToken: accessToken)
    }
    
    private func getAuthenticatedNetwork() -> AuthenticatedNetwork {
        guard let network = network else {
            fatalError("network need to be set before use")
        }
        
        return network
    }
    
    func createConversation(sender: String, didTapItem: @escaping (String, String) -> Void, didTapLogOut: @escaping () -> Void) -> some View {
        if conversationViewModel == nil {
            let userService = RemoteUserService(network: getAuthenticatedNetwork())
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
            let messageService = RemoteMessageService(secureKey: secureKeyService, keyStore: keyStore, decryptService: decryptService, network: getAuthenticatedNetwork())
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
