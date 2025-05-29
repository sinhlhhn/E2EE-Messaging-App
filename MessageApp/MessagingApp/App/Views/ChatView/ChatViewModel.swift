//
//  ChatViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 22/5/25.
//

import Foundation
import Observation
import Combine

@Observable
class ChatViewModel {
    //TODO: -should be let
    var sender: String
    var receiver: String
    let service: any SocketUseCase<String, TextMessage>
    let messageService: MessageUseCase
    var messages: [Message] = []
    var reachedTop: Bool = false
    
    private var firstMessageId: Int?
    var lastMessageId: Int?
    private var cancellable: AnyCancellable?
    private var connectCancellable: AnyCancellable?
    private var fetchMessageCancellable: AnyCancellable?
    
    private let didTapBack: () -> Void
    
    init(sender: String, receiver: String, service: any SocketUseCase<String, TextMessage>, messageService: MessageUseCase, didTapBack: @escaping () -> Void) {
        self.sender = sender
        self.receiver = receiver
        self.service = service
        self.messageService = messageService
        self.didTapBack = didTapBack
        fetchMessage()
    }
    
    func subscribe() {
        cancellable = service.subscribeToIncomingMessages()
            .sink { completion in
                switch completion {
                case .finished: debugPrint("socket finished")
                case .failure(let error):
                    //TODO: -should implement retry mechanism
                    debugPrint("socket get error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] response in
                if let id = Int(response.messageId) {
                    self?.messages.append(Message(messageId: id, content: response.message, isFromCurrentUser: false))
                } else {
                    debugPrint("❌ cannot get id from message")
                }
            }
        
        connect()
    }
    
    private func connect() {
        connectCancellable = service.connect(user: sender)
            .sink { completion in
                switch completion {
                    case .finished: debugPrint("socket connected")
                case .failure(let error):
                    //TODO: -show no connection state
                    debugPrint("socket get error: \(error.localizedDescription)")
                }
            } receiveValue: { _ in
                //TODO: -show connected state
                debugPrint("socket connected")
            }
    }
    
    func sendMessage(_ text: String) {
        messages.append(Message(messageId: 0, content: text, isFromCurrentUser: true))
        service.sendMessage(TextMessage(messageId: "", sender: sender, receiver: receiver, message: text))
    }
    
    func loadFirstMessage() {
        passthroughSubject.send(FetchMessageData(sender: sender, receiver: receiver, firstLoad: true))
    }
    
    func loadMoreMessages() {
        passthroughSubject.send(FetchMessageData(sender: sender, receiver: receiver, before: firstMessageId, limit: 10, firstLoad: false))
    }
    
    let passthroughSubject = PassthroughSubject<FetchMessageData, Never>()
    
    private func fetchMessage() {
        fetchMessageCancellable = passthroughSubject
            .delay(for: .seconds(2), scheduler: DispatchQueue.global())
            .flatMap(maxPublishers: .max(1)) { data in
                self.messageService.fetchMessages(data: data)
                    .replaceError(with: [])
            }
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .finished: debugPrint("fetch finish")
                case .failure(let error):
                    //TODO: -show error
                    debugPrint("❌ fetch get error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] messages in
                guard let self else { return }
                self.messages.insert(contentsOf: messages, at: 0)
                if let firstMessageId = messages.first?.messageId {
                    self.firstMessageId = firstMessageId
                }
                if let lastMessageId = messages.last?.messageId {
                    self.lastMessageId = lastMessageId
                }
                self.reachedTop = false
            }
    }
    
    func reset() {
        didTapBack()
        messages = []
    }
}
