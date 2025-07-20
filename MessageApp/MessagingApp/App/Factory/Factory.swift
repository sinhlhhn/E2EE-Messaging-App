//
//  Factory.swift
//  ReplaceNotificationCenterWithAdapter
//

import SwiftUI

typealias DataTaskHTTPClient = any HTTPClient<URLRequest, (Data, HTTPURLResponse)>

final class Factory {
    private lazy var pinning: PinningDelegate = ECCPinning()
    //MARK: -DataTask
    private lazy var sessionDelegate: URLSessionDelegate = DefaultSessionDelegate(pinning: pinning)
    private lazy var configuration: URLSessionConfiguration = URLSessionConfiguration.ephemeral
    private lazy var session = URLSession(configuration: configuration, delegate: sessionDelegate, delegateQueue: nil)
    private lazy var fetchClient: DataTaskHTTPClient = URLSessionDataTaskHTTPClient(session: session)
    
    private lazy var retryAuthenticatedClient: DataTaskHTTPClient = RetryAuthenticatedHTTPClient(client: fetchClient)
    private lazy var tokenProvider: TokenProvider = HTTPTokenProvider(network: retryAuthenticatedClient, keyStore: keyStore)
    
    //MARK: -UploadTask
    private lazy var progressDelegate = ProgressSessionDelegate(pinning: pinning)
    private lazy var uploadConfiguration: URLSessionConfiguration = URLSessionConfiguration.ephemeral
    private lazy var uploadSession = URLSession(configuration: uploadConfiguration, delegate: progressDelegate, delegateQueue: nil)
    private lazy var uploadClient = URLSessionUploadTaskHTTPClient(session: uploadSession)
    
    //MARK: -StreamUploadTask
    private lazy var streamUploadDelegate = StreamUploadSessionDelegate(pinning: pinning)
    private lazy var streamUploadSession = URLSession(configuration: .ephemeral, delegate: streamUploadDelegate, delegateQueue: nil)
    private lazy var streamUploadClient = URLSessionStreamUploadTaskHTTPClient(session: streamUploadSession, didCreateTask: streamUploadDelegate.createStream)
    
    //MARK: -DownloadTask
    private lazy var downloadConfiguration: URLSessionConfiguration = URLSessionConfiguration.ephemeral
    private lazy var downloadSession = URLSession(configuration: downloadConfiguration, delegate: progressDelegate, delegateQueue: nil)
    private lazy var downloadClient = URLSessionDownloadTaskHTTPClient(session: downloadSession)
    
    //MARK: -AuthenticatedClient
    private lazy var authenticatedClient = AuthenticatedHTTPClient(
        client: fetchClient,
        uploadClient: uploadClient,
        cancelUploadClient: uploadClient,
        streamUploadClient: streamUploadClient,
        downloadClient: downloadClient,
        cancelDownloadClient: downloadClient,
        tokenProvider: tokenProvider
    )
    private lazy var authenticatedNetwork: NetworkModule = AuthenticatedNetwork(
        network: authenticatedClient,
        uploadNetwork: authenticatedClient,
        downloadNetwork: authenticatedClient,
        progressSubscriber: progressDelegate,
        streamUpload: authenticatedClient
    )
    
    //MARK: -UnauthenticatedClient
    private lazy var unauthenticatedNetwork: UnauthenticatedNetworking = UnauthenticatedNetwork(network: fetchClient)
    
    
    private var conversationViewModel: ConversationViewModel?
    
    private lazy var keyStore = UserDefaultsKeyStoreService()
    private var chatViewModel: ChatViewModel?
    private var messageAttachmentViewModel: MessageAttachmentViewModel?
    
    
    private var loginViewModel: LoginViewModel?
    private var profileViewModel: ProfileViewModel?
}

// Root
extension Factory {
    func createRootView(didLogin: @escaping () -> Void, didGoToConversation: @escaping (User) -> Void) -> some View {
        let viewModel = SplashViewModel(tokenProvider: tokenProvider, keyStore: keyStore, needAuth: didLogin, didAuth: didGoToConversation)
        
        return SplashView(viewModel: viewModel)
            .onAppear {
                print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
                viewModel.checkAuthentication()
            }
    }
    
    func createLogIn(didLogin: @escaping (User) -> Void) -> some View {
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
    
    func createProfile() -> some View {
        if profileViewModel == nil {
            let profileService = ProfileService(network: authenticatedNetwork)
            profileViewModel = ProfileViewModel(service: profileService)
        }
        guard let profileViewModel = profileViewModel else {
            fatalError("profileViewModel need to be set before use ")
        }
        
        return ProfileView(viewModel: profileViewModel)
    }
    
    func createConversation(sender: User, didTapItem: @escaping (User, String) -> Void, didTapLogOut: @escaping () -> Void) -> some View {
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
    
    func createChat(sender: User, receiver: String, didTapBack: @escaping () -> Void) -> some View {
        if chatViewModel == nil {
            let encryptService = AESEncryptService()
            let decryptService = AESDecryption()
            let secureKeyService = P256SecureKeyService()
            let messageService = RemoteMessageService(secureKey: secureKeyService, keyStore: keyStore, decryptService: decryptService, network: authenticatedNetwork)
            let socketService = LocalSocketService(sessionDelegate: sessionDelegate, encryptService: encryptService, decryptService: decryptService, keyStore: keyStore)
            chatViewModel = ChatViewModel(sender: sender, receiver: receiver, service: socketService, uploadService: authenticatedNetwork, messageService: messageService, didTapBack: didTapBack)
        }
        
        guard let chatViewModel = chatViewModel else {
            fatalError("chatViewModel need to be set before use ")
        }
        
        chatViewModel.sender = sender
        chatViewModel.receiver = receiver
        
        return ChatView(viewModel: chatViewModel, didCreateMessageAttachmentViewModel: createAttachmentMessageViewModel)
    }
    
    private func createAttachmentMessageViewModel(attachmentMessage: AttachmentMessage) -> MessageAttachmentViewModel {
        if messageAttachmentViewModel == nil {
            messageAttachmentViewModel = MessageAttachmentViewModel(url: attachmentMessage.path, downloadNetwork: authenticatedNetwork)
        }
        return messageAttachmentViewModel!
    }
}

// Sub
extension Factory {
    
}
