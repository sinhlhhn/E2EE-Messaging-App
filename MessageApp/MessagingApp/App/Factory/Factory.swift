//
//  Factory.swift
//  ReplaceNotificationCenterWithAdapter
//

import SwiftUI

typealias DataTaskHTTPClient = any HTTPClient<URLRequest, (Data, HTTPURLResponse)>
typealias UploadTaskHTTPClient = any HTTPClient<(URLRequest, Data), (Data?, HTTPURLResponse)>

final class Factory {
    private lazy var pinningDelegate = ECCPinnedSessionDelegate()
    private lazy var configuration: URLSessionConfiguration = URLSessionConfiguration.ephemeral
    private lazy var session = URLSession(configuration: configuration, delegate: pinningDelegate, delegateQueue: nil)
    private lazy var fetchClient: DataTaskHTTPClient = URLSessionDataTaskHTTPClient(session: session)
    private lazy var uploadClient: UploadTaskHTTPClient = URLSessionUploadTaskHTTPClient(session: session)
    
    private lazy var retryAuthenticatedClient: DataTaskHTTPClient = RetryAuthenticatedHTTPClient(client: fetchClient)
    private lazy var tokenProvider: TokenProvider = HTTPTokenProvider(network: retryAuthenticatedClient, keyStore: keyStore)
    private lazy var authenticatedClient: DataTaskHTTPClient = AuthenticatedHTTPClient(client: fetchClient, tokenProvider: tokenProvider)
    
    private lazy var authenticatedNetwork: NetworkModule = AuthenticatedNetwork(network: authenticatedClient)
    
    private lazy var unauthenticatedNetwork: UnauthenticatedNetworking = UnauthenticatedNetwork(network: fetchClient)
    private var conversationViewModel: ConversationViewModel?
    
    private lazy var keyStore = UserDefaultsKeyStoreService()
    private var chatViewModel: ChatViewModel?
    
    
    private var loginViewModel: LoginViewModel?
}

// Root
extension Factory {
    func createRootView(didLogin: @escaping () -> Void, didGoToConversation: @escaping (String) -> Void) -> some View {
        let viewModel = SplashViewModel(tokenProvider: tokenProvider, keyStore: keyStore, needAuth: didLogin, didAuth: didGoToConversation)
        
        return SplashView(viewModel: viewModel)
            .onAppear {
                viewModel.checkAuthentication()
            }
    }
    
    func createLogIn(didLogin: @escaping (String) -> Void) -> some View {
        if loginViewModel == nil {
            let secureKeyService = P256SecureKeyService()
            let restoreKey = RemoteRestoreKeyModule()
            let authentication = PasswordAuthenticationService(unauthenticatedNetwork: unauthenticatedNetwork, network: authenticatedNetwork, secureKey: secureKeyService, keyStore: keyStore, restoreKey: restoreKey)
            loginViewModel = LoginViewModel(service: authentication, didLogin: didLogin)
        }
        guard let loginViewModel = loginViewModel else {
            fatalError("loginViewModel need to be set before use ")
        }
        
        return LogInView(viewModel: loginViewModel)
    }
    
    func createConversation(sender: String, didTapItem: @escaping (String, String) -> Void, didTapLogOut: @escaping () -> Void) -> some View {
        if conversationViewModel == nil {
            let userService = RemoteUserService(network: authenticatedNetwork)
            let logOut = RemoteLogOutUseCase(network: authenticatedNetwork, keyStore: keyStore)
            conversationViewModel = ConversationViewModel(sender: sender, logOutUseCase: logOut, service: userService, didTapItem: didTapItem, didTapLogOut: didTapLogOut)
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
            let messageService = RemoteMessageService(secureKey: secureKeyService, keyStore: keyStore, decryptService: decryptService, network: authenticatedNetwork)
            let socketService = LocalSocketService(sessionDelegate: pinningDelegate, encryptService: encryptService, decryptService: decryptService, keyStore: keyStore)
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
