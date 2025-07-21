//
//  ChatViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 22/5/25.
//

import Foundation
import Observation
import Combine

import SwiftUI
import PhotosUI

@Observable
class ChatViewModel {
    //TODO: -should be let
    var sender: User
    var receiver: String
    private let service: any SocketUseCase<String, SocketMessage>
    private let uploadService: NetworkModule
    private let messageService: MessageUseCase
    var messages: [Message] = []
    var reachedTop: Bool = false
    
    private var firstMessageId: Int?
    var lastMessageId: Int?
    private var cancellable: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []
    private var connectCancellable: AnyCancellable?
    private var fetchMessageCancellable: AnyCancellable?
    private let passthroughSubject = PassthroughSubject<FetchMessageData, Never>()
    
    private let didTapBack: () -> Void
    
    var imageSelection: PhotosPickerItem?
    
    init(
        sender: User,
        receiver: String,
        service: any SocketUseCase<String, SocketMessage>,
        uploadService: NetworkModule,
        messageService: MessageUseCase,
        didTapBack: @escaping () -> Void
    ) {
        self.sender = sender
        self.receiver = receiver
        self.service = service
        self.uploadService = uploadService
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
                    self?.messages.append(Message(messageId: id, type: response.messageType, isFromCurrentUser: false))
                } else {
                    debugPrint("❌ cannot get id from message")
                }
            }
        
        connect()
    }
    
    private func connect() {
        connectCancellable = service.connect(user: sender.username)
            .sink { completion in
                switch completion {
                    case .finished: debugPrint("socket finished")
                case .failure(let error):
                    //TODO: -show no connection state
                    debugPrint("socket get error: \(error.localizedDescription)")
                }
            } receiveValue: { _ in
                //TODO: -show connected state
                debugPrint("socket connected")
            }
    }
    
    func sendMessage(_ type: MessageType) {
        switch type {
        case .text(let textData):
            service.sendMessage(SocketMessage(messageId: "", sender: sender.username, receiver: receiver, messageType: type))
        case .image(let VideoMessage):
            //TODO: handle image
            break
        case .video(let videoData):
            uploadService.uploadFile(data: UploadFileData(url: videoData.path, fileSize: videoData.fileSize, userId: String(sender.id)))
                .sink { completion in
                    switch completion {
                    case .finished: print("uploadFile finished")
                    case .failure(let error): print("uploadFile failure")
                    }
                } receiveValue: { _ in
                    print("uploadFile receiveValue")
                }
                .store(in: &cancellables)
            
        case .attachment(let attachment):
            uploadService.uploadFile(data: UploadFileData(url: attachment.path, fileSize: attachment.fileSize, userId: String(sender.id)))
                .sink { completion in
                    switch completion {
                    case .finished: print("uploadFile finished")
                    case .failure(let error): print("uploadFile failure")
                    }
                } receiveValue: { [weak self] response in
                    guard let self else { return }
                    print("uploadFile receiveValue")
                    //TODO: -Currently, the owner also need to download the file from the server and then save to the Document/Download folder. We may need to move the file to the Document/Download folder to prevent unnecessary network call. It quite complex because currently, we let the server to generate the file name to avoid duplicated file.
                    service.sendMessage(SocketMessage(messageId: "", sender: self.sender.username, receiver: self.receiver, messageType: .attachment(.init(path: URL(string: response.path)!))))
                }
                .store(in: &cancellables)
        }
        messages.append(Message(messageId: 0, type: type, isFromCurrentUser: true))
        
    }
    
    func loadFirstMessage() {
        passthroughSubject.send(FetchMessageData(sender: sender.username, receiver: receiver, firstLoad: true))
    }
    
    func loadMoreMessages() {
        passthroughSubject.send(FetchMessageData(sender: sender.username, receiver: receiver, before: firstMessageId, limit: 10, firstLoad: false))
    }
    
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
        service.disconnect()
        didTapBack()
        messages = []
    }
}
