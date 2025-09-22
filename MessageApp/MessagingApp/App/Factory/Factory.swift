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
    
    private lazy var keyStore = UserDefaultsKeyStoreService()
    
    lazy var secureKeyService = P256SecureKeyService()
    lazy var restoreKey = RemoteRestoreKeyModule()
    lazy var authentication = PasswordAuthenticationService(unauthenticatedNetwork: unauthenticatedNetwork, network: authenticatedNetwork, secureKey: secureKeyService, keyStore: keyStore, restoreKey: restoreKey)
    
    lazy var userService = RemoteUserService(network: authenticatedNetwork)
    lazy var logOut = RemoteLogOutUseCase(network: authenticatedNetwork, keyStore: keyStore)
    
    
    lazy var encryptService = AESEncryptService()
    lazy var decryptService = AESDecryption()
    lazy var messageService = RemoteMessageService(secureKey: secureKeyService, keyStore: keyStore, decryptService: decryptService, network: authenticatedNetwork)
    lazy var socketService = LocalSocketService(sessionDelegate: sessionDelegate, encryptService: encryptService, decryptService: decryptService, keyStore: keyStore)
}

// Root
extension Factory {
    func createRootView(didLogin: @escaping () -> Void, didGoToConversation: @escaping (User) -> Void) -> some View {
        let viewModel = SplashViewModel(tokenProvider: tokenProvider, keyStore: keyStore, needAuth: didLogin, didAuth: didGoToConversation)
//        print("❌ ", Unmanaged.passUnretained(viewModel).toOpaque())
        return SplashView(viewModel: viewModel)
    }
    
    func createLogIn(didLogin: @escaping (User) -> Void) -> some View {
        let loginViewModel = LoginViewModel(service: authentication, didLogin: didLogin)
        
        return LogInView(viewModel: loginViewModel)
    }
    
    func createProfile() -> some View {
        return EmptyView()
//        if profileViewModel == nil {
//            let profileService = ProfileService(network: authenticatedNetwork)
//            profileViewModel = ProfileViewModel(service: profileService)
//        }
//        guard let profileViewModel = profileViewModel else {
//            fatalError("profileViewModel need to be set before use ")
//        }
//        
//        return ProfileView(viewModel: profileViewModel)
    }
    
    func createConversation(sender: User, didTapItem: @escaping (User, String) -> Void, didTapLogOut: @escaping () -> Void) -> some View {
        let conversationViewModel = ConversationViewModel(
            sender: sender,
            logOutUseCase: logOut,
            service: userService,
            didTapItem: didTapItem,
            didTapLogOut: didTapLogOut
        )
        
        print("❌ ", Unmanaged.passUnretained(conversationViewModel).toOpaque())
        return ConversationView(viewModel: conversationViewModel)
    }
    
    func createChat(sender: User, receiver: String, didTapBack: @escaping () -> Void, didDisplayDocument: @escaping (URL) -> Void) -> some View {
        let chatViewModel = ChatViewModel(sender: sender, receiver: receiver, service: socketService, uploadService: authenticatedNetwork, messageService: messageService, didTapBack: didTapBack)
        
        chatViewModel.sender = sender
        chatViewModel.receiver = receiver
        
        return ChatView(
            viewModel: chatViewModel) { [weak self] reachedTop, lastMessageId, messages, isFocused in
                guard let self else { fatalError() }
                return createChatView(reachedTop: reachedTop, lastMessageId: lastMessageId, messages: messages, isFocused: isFocused, didDisplayDocument: didDisplayDocument)
            }
    }
    
    private func createChatView(reachedTop: Binding<Bool>, lastMessageId: Binding<Int?>, messages: Binding<[MessageGroup]>, isFocused: FocusState<Bool>.Binding, didDisplayDocument: @escaping (URL) -> Void) -> MessageListView {
        MessageListView(
            reachedTop: reachedTop,
            previousId: lastMessageId,
            isFocused: isFocused,
            viewModel: createMessageListViewModel(),
            messages: messages,
            didCreateMessageAttachmentViewModel: { [unowned self] attachment in
                createAttachmentMessageViewModel(attachmentMessage: attachment)
            },
            didCreateMessageImageViewModel: { [unowned self] image in
                createMessageImageViewModel(message: image)
            },
            didCreateGroupMessageImageViewModel: { [unowned self] groupImage in
                createGroupMessageImageViewModel(groupImage)
            },
            didCreateMessageVideoViewModel: { [unowned self] video in
                createMessageVideoViewModel(message: video)
            },
            didDisplayDocument: didDisplayDocument
        )
    }
    
    private func createMessageListViewModel() -> MessageListViewModel {
        MessageListViewModel()
    }
    
    private func createGroupMessageImageViewModel(_ messages: [ImageMessage]) -> GroupMessageImageViewModel {
        GroupMessageImageViewModel(message: messages, downloadNetwork: authenticatedNetwork)
    }
    
    private func createMessageVideoViewModel(message: VideoMessage) -> MessageVideoViewModel {
        MessageVideoViewModel(message: message, downloadNetwork: authenticatedNetwork)
    }
    
    private func createAttachmentMessageViewModel(attachmentMessage: AttachmentMessage) -> MessageAttachmentViewModel {
        MessageAttachmentViewModel(attachmentMessage: attachmentMessage, downloadNetwork: authenticatedNetwork)
    }
    
    private func createMessageImageViewModel(message: ImageMessage) -> MessageImageViewModel {
        MessageImageViewModel(message: message, downloadNetwork: authenticatedNetwork)
    }
}

// Sub
extension Factory {
    
}
